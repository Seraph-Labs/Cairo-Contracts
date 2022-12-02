""" ERC2114 token test"""
import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert
from utils.accounts_utils import Account

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join(
    "SeraphLabs", "contracts", "mocks", "tokens", "mock_2114enumerable.cairo"
)
from utils.openzepplin.utils import (
    assert_revert,
    assert_sorted_event_emitted,
)

FAKE_PKEY = 123456789987654321
NUM_OF_ACC = 3


@pytest_asyncio.fixture(scope="module")
async def account_factory():
    starknet = await Starknet.empty()
    accounts = []
    for i in range(NUM_OF_ACC):
        account = Account(FAKE_PKEY + i)
        await account.create(starknet)
        accounts.append(account)
        print(f"Account {i} initalized: {account}")
    return starknet, accounts


@pytest_asyncio.fixture(scope="module")
async def contract_factory(account_factory):
    starknet, accounts = account_factory
    name = str_to_felt("211LP")
    symbol = str_to_felt("FTH")
    token_contract = await starknet.deploy(
        source=MOCK_FILE, constructor_calldata=[name, symbol]
    )
    return starknet, accounts, token_contract


@pytest.mark.asyncio
async def test_account_contract(contract_factory):
    _, accounts, _ = contract_factory
    user_1 = accounts[0]
    pkey = await user_1.contract.getPublicKey().call()
    assert pkey.result == (user_1.public_key,)


@pytest.mark.asyncio
async def test_mint(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]
    qty1 = (5, 0)
    qty2 = (10, 0)
    qty3 = (5, 0)
    qty4 = (1, 0)

    await user_1.tx_with_nonce(token_contract.contract_address, "mint", [*qty1])
    await user_2.tx_with_nonce(token_contract.contract_address, "mint", [*qty2])
    await user_1.tx_with_nonce(token_contract.contract_address, "mint", [*qty3])
    await user_3.tx_with_nonce(token_contract.contract_address, "mint", [*qty4])

    bal1 = await token_contract.balanceOf(user_1.address).call()
    bal2 = await token_contract.balanceOf(user_2.address).call()
    bal3 = await token_contract.balanceOf(user_3.address).call()
    supply = await token_contract.totalSupply().call()
    assert supply.result == ((21, 0),)
    assert bal1.result == ((10, 0),)
    assert bal2.result == ((10, 0),)
    assert bal3.result == ((1, 0),)


# users  [  1 |   2  |   1   | 3 ]
# tokens [1-5 | 6-15 | 16-20 | 21]
@pytest.mark.asyncio
async def test_ownerOf(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]

    # check 1st in batch
    own_1 = await token_contract.ownerOf((1, 0)).call()
    # check middle in batch
    own_11 = await token_contract.ownerOf((11, 0)).call()
    # check last in batch
    own_20 = await token_contract.ownerOf((20, 0)).call()
    # check not in batch
    own_21 = await token_contract.ownerOf((21, 0)).call()

    assert own_1.result == (user_1.address,)
    assert own_11.result == (user_2.address,)
    assert own_20.result == (user_1.address,)
    assert own_21.result == (user_3.address,)

    await assert_revert(
        token_contract.ownerOf((22, 0)).call(),
        reverted_with="ERC721S: tokenId does not exist yet",
    )


# users  [  1 |   2  |   1   | 3 ]
# tokens [1-5 | 6-15 | 16-20 | 21]
@pytest.mark.asyncio
async def test_transferFrom(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]

    token_1 = (1, 0)
    token_7 = (7, 0)
    token_20 = (20, 0)
    token_21 = (21, 0)

    # transfer 1st in batch
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_1.address, user_3.address, *token_1],
    )
    # transfer last in batch
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_1.address, user_3.address, *token_20],
    )
    # transfer middle in batch
    await user_2.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_2.address, user_3.address, *token_7],
    )
    # transfer not in batch
    await user_3.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_3.address, user_2.address, *token_21],
    )

    # test balance
    bal1 = await token_contract.balanceOf(user_1.address).call()
    bal2 = await token_contract.balanceOf(user_2.address).call()
    bal3 = await token_contract.balanceOf(user_3.address).call()
    assert bal1.result == ((8, 0),)
    assert bal2.result == ((10, 0),)
    assert bal3.result == ((3, 0),)

    # test owner of
    owner_6 = await token_contract.ownerOf(token_7).call()
    owner_19 = await token_contract.ownerOf((19, 0)).call()
    assert owner_6.result == (user_3.address,)
    assert owner_19.result == (user_1.address,)

    # test assertion error for not owned token
    await assert_revert(
        user_3.tx_with_nonce(
            token_contract.contract_address,
            "transferFrom",
            [user_1.address, user_3.address, *(5, 0)],
        ),
        reverted_with="ERC721S: either is not approved or the caller is the zero address",
    )
    # test assertion error for non existing token
    await assert_revert(
        user_3.tx_with_nonce(
            token_contract.contract_address,
            "transferFrom",
            [0, user_3.address, *(22, 0)],
        ),
        reverted_with="ERC721S: tokenId does not exist yet",
    )


#! start from here
# user   [3 |  1  | 2 | 3 |   2  |   1   |  3 |  2 ]
# tokens [1 | 2-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_scalarTransfer(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]

    # transfer not in batch
    tx_info_1 = await user_3.tx_with_nonce(
        token_contract.contract_address,
        "scalarTransferFrom",
        [user_3.address, *(1, 0), *(20, 0)],
    )

    # transfer start of batch
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "scalarTransferFrom",
        [user_1.address, *(2, 0), *(17, 0)],
    )

    # transfer mid of batch
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "scalarTransferFrom",
        [user_1.address, *(4, 0), *(17, 0)],
    )

    # transfer last of batch
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "scalarTransferFrom",
        [user_1.address, *(5, 0), *(17, 0)],
    )

    # approve transfer
    await user_2.tx_with_nonce(
        token_contract.contract_address, "approve", [user_1.address, *(6, 0)]
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "scalarTransferFrom",
        [user_2.address, *(6, 0), *(5, 0)],
    )

    # test event
    # assert_sorted_event_emitted(
    #    tx_info_1,
    #    from_address=token_contract.contract_address,
    #    name="ScalarTransfer",
    #    data=[user_3.address, *(1, 0), *(20, 0), 0],
    # )

    # check token of
    res1 = await token_contract.tokenOf((1, 0)).call()
    res2 = await token_contract.tokenOf((2, 0)).call()
    res3 = await token_contract.tokenOf((4, 0)).call()
    res4 = await token_contract.tokenOf((6, 0)).call()
    assert res1.result == ((20, 0), token_contract.contract_address)
    assert res2.result == ((17, 0), token_contract.contract_address)
    assert res3.result == ((17, 0), token_contract.contract_address)
    assert res4.result == ((5, 0), token_contract.contract_address)

    # check token balance
    bal1 = await token_contract.tokenBalanceOf((20, 0)).call()
    bal2 = await token_contract.tokenBalanceOf((17, 0)).call()
    assert bal1.result == ((1, 0),)
    assert bal2.result == ((3, 0),)

    # assert revert if token does not exist
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "scalarTransferFrom",
            [user_1.address, *(17, 0), *(22, 0)],
        ),
        reverted_with="ERC2114: tokeId does not exist",
    )

    # assert revert if token is owned by another token
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "scalarTransferFrom",
            [user_1.address, *(2, 0), *(15, 0)],
        ),
        reverted_with="ERC2114: tokenId already owned by another token",
    )


# token_o  [20 | 17 |  0  | 17  | 5 ]
# user     [0 |  0  |  1 |  0  | 0 | 3 |   2  |   1   |  3 |  2 ]
# tokens   [1 |  2  | 3 | 4-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_tokenOfToken_index(contract_factory):
    _, _, token_contract = contract_factory

    res1 = await token_contract.tokenOfTokenByIndex((17, 0), (0, 0)).call()
    res2 = await token_contract.tokenOfTokenByIndex((17, 0), (1, 0)).call()
    res3 = await token_contract.tokenOfTokenByIndex((17, 0), (2, 0)).call()
    res4 = await token_contract.tokenOfTokenByIndex((20, 0), (0, 0)).call()
    res5 = await token_contract.tokenOfTokenByIndex((5, 0), (0, 0)).call()

    assert res1.result == ((2, 0), token_contract.contract_address)
    assert res2.result == ((4, 0), token_contract.contract_address)
    assert res3.result == ((5, 0), token_contract.contract_address)
    assert res4.result == ((1, 0), token_contract.contract_address)
    assert res5.result == ((6, 0), token_contract.contract_address)


# token_o  [20 | 17 |  0  | 17  | 5 ]
# user     [0 |  0  |  1 |  0  | 0 | 3 |   2  |   1   |  3 |  2 ]
# tokens   [1 |  2  | 3 | 4-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_scalarRemove(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]

    await assert_revert(
        user_3.tx_with_nonce(
            token_contract.contract_address,
            "scalarRemoveFrom",
            [*(5, 0), *(6, 0)],
        ),
        reverted_with="ERC2114: caller is either not approved or is a zero address",
    )

    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "scalarRemoveFrom",
            [*(17, 0), *(6, 0)],
        ),
        reverted_with="ERC2114 : token does not own this tokenId",
    )
    # approve transfer
    await user_1.tx_with_nonce(
        token_contract.contract_address, "approve", [user_3.address, *(17, 0)]
    )

    tx_info_1 = await user_3.tx_with_nonce(
        token_contract.contract_address,
        "scalarRemoveFrom",
        [*(5, 0), *(6, 0)],
    )

    await user_3.tx_with_nonce(
        token_contract.contract_address, "scalarRemoveFrom", [*(20, 0), *(1, 0)]
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address, "scalarRemoveFrom", [*(17, 0), *(2, 0)]
    )

    # test event
    assert_sorted_event_emitted(
        tx_info_1,
        from_address=token_contract.contract_address,
        name="ScalarRemove",
        data=[*(5, 0), *(6, 0), user_1.address],
    )

    # test tokenOf
    res1 = await token_contract.tokenOf((1, 0)).call()
    assert res1.result == ((0, 0), 0)

    # test balanceOf
    bal1 = await token_contract.tokenBalanceOf((20, 0)).call()
    bal2 = await token_contract.tokenBalanceOf((17, 0)).call()
    assert bal1.result == ((0, 0),)
    assert bal2.result == ((2, 0),)

    # test ownerOf
    own1 = await token_contract.ownerOf((6, 0)).call()
    assert own1.result == (user_1.address,)


# token_o  [0  |  0   |  0  | 17  | 0 ]
# user     [3 |  1  |  1  |  0  | 1 | 3 |   2  |   1   |  3 |  2 ]
# tokens   [1 |  2  |  3  | 4-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_tokenOfToken_index_2(contract_factory):
    _, _, token_contract = contract_factory

    res1 = await token_contract.tokenOfTokenByIndex((17, 0), (0, 0)).call()
    res2 = await token_contract.tokenOfTokenByIndex((17, 0), (1, 0)).call()

    assert res1.result == ((5, 0), token_contract.contract_address)
    assert res2.result == ((4, 0), token_contract.contract_address)
