""" ERC721S token test"""
import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert
from utils.accounts_utils import Account
from utils.argHandler import ascii_to_felt, felt_to_ascii, unpack_tpl

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join(
    "SeraphLabs", "contracts", "mocks", "tokens", "mock_2114.cairo"
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
async def test_owner_index(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]

    # get first in loop
    res1 = await token_contract.tokenOfOwnerByIndex(user_1.address, (0, 0)).call()
    assert res1.result == ((2, 0),)
    # get middle in loop
    res2 = await token_contract.tokenOfOwnerByIndex(user_1.address, (4, 0)).call()
    assert res2.result == ((17, 0),)
    # get last in loop
    res3 = await token_contract.tokenOfOwnerByIndex(user_2.address, (7, 0)).call()
    assert res3.result == ((15, 0),)
    # get first existing id
    res4 = await token_contract.tokenOfOwnerByIndex(user_3.address, (0, 0)).call()
    assert res4.result == ((1, 0),)
    # get last existing id
    res5 = await token_contract.tokenOfOwnerByIndex(user_3.address, (2, 0)).call()
    assert res5.result == ((20, 0),)
    # get onwed token index
    res6 = await token_contract.tokenOfOwnerByIndex(
        token_contract.contract_address, (0, 0)
    ).call()
    assert res6.result == ((4, 0),)
    res7 = await token_contract.tokenOfOwnerByIndex(
        token_contract.contract_address, (1, 0)
    ).call()
    assert res7.result == ((5, 0),)

    await assert_revert(
        token_contract.tokenOfOwnerByIndex(user_2.address, (9, 0)).call(),
        reverted_with="ERC721S: index is out of bounds",
    )


# token_o  [0  |  0   |  0  | 17  | 0 ]
# user     [3 |  1  |  1  |  0  | 1 | 3 |   2  |   1   |  3 |  2 ]
# tokens   [1 |  2  |  3  | 4-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_token_by_index(contract_factory):
    _, _, token_contract = contract_factory

    res1 = await token_contract.tokenByIndex((0, 0)).call()
    assert res1.result == ((1, 0),)

    res2 = await token_contract.tokenByIndex((1, 0)).call()
    assert res2.result == ((2, 0),)

    res3 = await token_contract.tokenByIndex((5, 0)).call()
    assert res3.result == ((6, 0),)

    res4 = await token_contract.tokenByIndex((8, 0)).call()
    assert res4.result == ((9, 0),)

    res5 = await token_contract.tokenByIndex((14, 0)).call()
    assert res5.result == ((15, 0),)

    res6 = await token_contract.tokenByIndex((16, 0)).call()
    assert res6.result == ((17, 0),)

    await assert_revert(
        token_contract.tokenByIndex((21, 0)).call(),
        reverted_with="ERC721S: index is out of bounds",
    )


# token_o  [0  |  0   |  0  | 17  | 0 ]
# user     [3 |  1  |  1  |  0  | 1 | 3 |   2  |   1   |  3 |  2 ]
# tokens   [1 |  2  |  3  | 4-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_add_attribute(contract_factory):
    _, accounts, token_contract = contract_factory

    user_1 = accounts[0]
    str1 = ascii_to_felt("hello")
    str2 = ascii_to_felt("world")
    str3 = ascii_to_felt("apple")
    tx_info_1 = await user_1.tx_with_nonce(
        token_contract.contract_address,
        "createAttribute",
        [*(1, 0), *(str1, 5)],
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "createAttribute",
        [*(2, 0), *(str2, 5)],
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "createAttribute",
        [*(3, 0), *(str3, 5)],
    )

    # check that attrId cannot be created twice
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "createAttribute",
            [*(1, 0), *(str1, 5)],
        ),
        reverted_with="ERC2114: attrId already exist",
    )

    # check that strObj cannot be invalid
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "createAttribute",
            [*(4, 0), *(0, 0)],
        ),
        reverted_with="ERC2114: String object is invalid",
    )

    # test event
    assert_sorted_event_emitted(
        tx_info_1,
        from_address=token_contract.contract_address,
        name="AttributeCreated",
        data=[*(1, 0), *(str1, 5)],
    )

    # add attributes
    tx_info_2 = await user_1.tx_with_nonce(
        token_contract.contract_address,
        "addAttribute",
        [*(2, 0), *(1, 0), *(str2, 5), *(1, 0)],
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "addAttribute",
        [*(2, 0), *(2, 0), *(0, 0), *(5, 0)],
    )

    # test event
    assert_sorted_event_emitted(
        tx_info_2,
        from_address=token_contract.contract_address,
        name="AttributeAdded",
        data=[*(2, 0), *(1, 0), *(str2, 5), *(1, 0)],
    )

    # test view funcs
    arr1 = await token_contract.attributesOf((2, 0)).call()
    count1 = await token_contract.attributesCount((2, 0)).call()
    ammt1 = await token_contract.attributesAmmount((2, 0), (1, 0)).call()
    ammt2 = await token_contract.attributesAmmount((2, 0), (2, 0)).call()
    val1 = await token_contract.attributeValue((2, 0), (1, 0)).call()
    val2 = await token_contract.attributeValue((2, 0), (2, 0)).call()
    assert arr1.result == ([(1, 0), (2, 0)],)
    assert count1.result == ((2, 0),)
    assert ammt1.result == ((1, 0),)
    assert ammt2.result == ((5, 0),)
    assert val1.result == ((str2, 5),)
    assert val2.result == ((0, 0),)

    # assert cant add non existent attribute
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "addAttribute",
            [*(2, 0), *(4, 0), *(str2, 5), *(1, 0)],
        ),
        reverted_with="ERC2114: attrId does not exist",
    )
    # assert attribute ammount cant be invalid
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "addAttribute",
            [*(2, 0), *(3, 0), *(str2, 5), *(0, 0)],
        ),
        reverted_with="ERC2114: ammount is not a valid uint",
    )
    # assert cant add attribute twice
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "addAttribute",
            [*(2, 0), *(1, 0), *(str2, 5), *(1, 0)],
        ),
        reverted_with="ERC2114: tokenId already owns this attrId",
    )


# token_o  [0  |  0   |  0  | 17  | 0 ]
# user     [3 |  1  |  1  |  0  | 1 | 3 |   2  |   1   |  3 |  2 ]
# tokens   [1 |  2  |  3  | 4-5 | 6 | 7 | 8-15 | 16-19 | 20 | 21]
@pytest.mark.asyncio
async def test_batch_add_attribute(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]

    str1 = ascii_to_felt("test1")
    str2 = ascii_to_felt("test2")
    str3 = ascii_to_felt("test3")
    str4 = ascii_to_felt("test4")

    arr1 = [(4, 0), (5, 0), (6, 0), (7, 0)]
    arr2 = [(str1, 5), (str2, 5), (str3, 5), (str4, 5)]
    arr3 = [(str1, 5), (str2, 5), (str3, 5), (0, 0)]
    ammtarr = [(1, 0), (2, 0), (3, 0), (4, 0)]
    fail_arr1 = [(4, 0), (3, 0), (6, 0), (7, 0)]

    # check that attrId cannot be created twice
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "batchCreateAttribute",
            [len(fail_arr1), *unpack_tpl(fail_arr1), len(arr2), *unpack_tpl(arr2)],
        ),
        reverted_with="ERC2114: attrId already exist",
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "batchCreateAttribute",
        [len(arr1), *unpack_tpl(arr1), len(arr2), *unpack_tpl(arr2)],
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "batchAddAttribute",
        [
            *(2, 0),
            len(arr1),
            *unpack_tpl(arr1),
            len(arr3),
            *unpack_tpl(arr3),
            len(ammtarr),
            *unpack_tpl(ammtarr),
        ],
    )

    # test view funcs
    arr1 = await token_contract.attributesOf((2, 0)).call()
    count1 = await token_contract.attributesCount((2, 0)).call()
    ammt1 = await token_contract.attributesAmmount((2, 0), (4, 0)).call()
    ammt2 = await token_contract.attributesAmmount((2, 0), (6, 0)).call()
    val1 = await token_contract.attributeValue((2, 0), (5, 0)).call()
    val2 = await token_contract.attributeValue((2, 0), (7, 0)).call()
    assert arr1.result == ([(1, 0), (2, 0), (4, 0), (5, 0), (6, 0), (7, 0)],)
    assert count1.result == ((6, 0),)
    assert ammt1.result == ((1, 0),)
    assert ammt2.result == ((3, 0),)
    assert val1.result == ((str2, 5),)
    assert val2.result == ((0, 0),)
