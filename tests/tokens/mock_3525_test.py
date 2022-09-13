""" ERC3525 token test"""
import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert, assert_event_emitted
from utils.argHandler import unpack_tpl, arr_res
from utils.accounts_utils import Account

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join(
    "SeraphLabs", "contracts", "mocks", "tokens", "mock_3525.cairo"
)

FAKE_PKEY = 123456789987654321
NUM_OF_ACC = 4

DATA = [0x34, 0x21, 0x55]
slot_1 = (1, 0)
slot_2 = (2, 0)
slot_3 = (3, 0)
slot_4 = (4, 0)


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
async def test_safeMint(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]
    units_10 = (10, 0)

    tx_info_1 = await user_1.tx_with_nonce(
        token_contract.contract_address,
        "safeMint",
        [*(1, 0), *slot_1, *units_10, len(DATA), *DATA],
    )
    tx_info_2 = await user_2.tx_with_nonce(
        token_contract.contract_address,
        "safeMint",
        [*(10, 0), *slot_2, *(0, 0), len(DATA), *DATA],
    )
    await user_3.tx_with_nonce(
        token_contract.contract_address,
        "safeMint",
        [*(10, 0), *slot_1, *(0, 0), len(DATA), *DATA],
    )

    # check owners balance and supply
    bal1 = await token_contract.balanceOf(user_1.address).call()
    bal2 = await token_contract.balanceOf(user_2.address).call()
    bal3 = await token_contract.balanceOf(user_3.address).call()
    supply = await token_contract.totalSupply().call()
    assert supply.result == ((21, 0),)
    assert bal1.result == ((1, 0),)
    assert bal2.result == ((10, 0),)
    assert bal3.result == ((10, 0),)

    # check slot supply
    sup1 = await token_contract.supplyOfSlot(slot_1).call()
    sup2 = await token_contract.supplyOfSlot(slot_2).call()
    assert sup1.result == ((11, 0),)
    assert sup2.result == ((10, 0),)

    # check units in token
    _unit1 = await token_contract.unitsInToken((1, 0)).call()
    assert _unit1.result == (units_10,)

    # check for event emmited
    assert_event_emitted(
        tx_info_1,
        from_address=token_contract.contract_address,
        name="Transfer",
        data=[0, user_1.address, *(1, 0)],
    )
    assert_event_emitted(
        tx_info_2,
        order=1,
        from_address=token_contract.contract_address,
        name="Transfer",
        data=[0, user_2.address, *(3, 0)],
    )


# users   [  1 |   2  |   3   ]
# units   [ 10 |   0  |   0   ]
# slot    [ 1  |   2  |   1   ]
# tokens  [ 1  | 2-11 | 12-21 ]
@pytest.mark.asyncio
async def test_split(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    units_1 = (1, 0)
    units_2 = (2, 0)
    units_3 = (3, 0)
    unit_arr = [units_1, units_1, units_1, units_2, units_3]  # total 7 units
    bad_arr1 = [units_1, (0, 0), units_1]
    bad_arr2 = [units_1, units_3, units_1]

    tx_info_1 = await user_1.tx_with_nonce(
        token_contract.contract_address,
        "split",
        [*(1, 0), len(unit_arr), *unpack_tpl(unit_arr)],
    )
    # check returned array
    # assert tx_info_1.result == (
    #    (arr_res([(22, 0), (23, 0), (24, 0), (25, 0), (26, 0)])),
    # )

    # check balance user 1 split tokenId 1 into 5 more tokens balance should be 6
    bal1 = await token_contract.balanceOf(user_1.address).call()
    assert bal1.result == ((6, 0),)

    # check slot balance should be
    sup1 = await token_contract.supplyOfSlot(slot_1).call()
    assert sup1.result == ((16, 0),)

    # check units
    _units1 = await token_contract.unitsInToken((1, 0)).call()
    _units23 = await token_contract.unitsInToken((23, 0)).call()
    _units25 = await token_contract.unitsInToken((25, 0)).call()
    _units26 = await token_contract.unitsInToken((26, 0)).call()
    assert _units1.result == ((2, 0),)
    assert _units23.result == ((0, 0),)
    assert _units25.result == ((1, 0),)
    assert _units26.result == ((2, 0),)

    # check owner of
    own1 = await token_contract.ownerOf((1, 0)).call()
    own22 = await token_contract.ownerOf((22, 0)).call()
    own24 = await token_contract.ownerOf((24, 0)).call()
    own26 = await token_contract.ownerOf((26, 0)).call()
    assert own1.result == (user_1.address,)
    assert own22.result == (user_1.address,)
    assert own24.result == (user_1.address,)
    assert own26.result == (user_1.address,)

    # check total supply
    supply = await token_contract.totalSupply().call()
    assert supply.result == ((26, 0),)

    # check owner

    # check split event
    # assert_event_emitted(
    #    tx_info_1,
    #    order=2,
    #    from_address=token_contract.contract_address,
    #    name="Split",
    #    data=[user_1.address, *(1, 0), *(24, 0), *(1, 0)],
    # )

    # assert_event_emitted(
    #    tx_info_1,
    #    order=3,
    #    from_address=token_contract.contract_address,
    #    name="Split",
    #    data=[user_1.address, *(1, 0), *(25, 0), *(2, 0)],
    # )

    # check that non-owner cant split
    await assert_revert(
        user_2.tx_with_nonce(
            token_contract.contract_address,
            "split",
            [*(1, 0), len(unit_arr), *unpack_tpl(unit_arr)],
        ),
        reverted_with="ERC3525: caller is not approved for all or not owner of token",
    )

    # check cant split if toke nhas 0 units
    await assert_revert(
        user_2.tx_with_nonce(
            token_contract.contract_address,
            "split",
            [*(2, 0), len(unit_arr), *unpack_tpl(unit_arr)],
        ),
        reverted_with="ERC3525: token has zero units",
    )

    # ensure cant have list of units that contains a 0
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "split",
            [*(26, 0), len(bad_arr1), *unpack_tpl(bad_arr1)],
        ),
        reverted_with="ERC3525: units in array cannot be zero",
    )

    # ensure cant split more units than token has
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "split",
            [*(26, 0), len(bad_arr2), *unpack_tpl(bad_arr2)],
        ),
        reverted_with="ERC3525: token does not have enough units",
    )


@pytest.mark.asyncio
async def test_getOwnerTokens(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    res1 = await token_contract.getOwnerTokens(user_1.address).call()
    assert res1.result == (
        [
            (1, 0),
            (22, 0),
            (23, 0),
            (24, 0),
            (25, 0),
            (26, 0),
        ],
    )


# users   [  1 |   2  |   3   |   1   |  1 |  1  ]
# units   [  2 |   0  |   0   |   0   |  1 |  2  ]
# slot    [ 1  |   2  |   1   |   1   |  1 |  1  ]
# tokens  [ 1  | 2-11 | 12-21 | 22-24 | 25 |  26 ]
@pytest.mark.asyncio
async def test_approve(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_3 = accounts[2]
    user_4 = accounts[3]

    tx_info_1 = await user_1.tx_with_nonce(
        token_contract.contract_address,
        "unitApprove",
        [user_4.address, *(26, 0), *(2, 0)],
    )

    # check for allowance
    allowance = await token_contract.allowance((26, 0), user_4.address).call()
    assert allowance.result == ((2, 0),)

    # check for event
    assert_event_emitted(
        tx_info_1,
        from_address=token_contract.contract_address,
        name="ApprovalUnits",
        data=[user_1.address, user_4.address, *(26, 0), *(2, 0)],
    )

    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "unitApprove",
        [user_3.address, *(26, 0), *(2, 0)],
    )
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "unitApprove",
        [user_4.address, *(26, 0), *(1, 0)],
    )

    # check for allowance
    allowance2 = await token_contract.allowance((26, 0), user_3.address).call()
    allowance3 = await token_contract.allowance((26, 0), user_4.address).call()
    assert allowance2.result == ((2, 0),)
    assert allowance3.result == ((1, 0),)

    # check reverts
    await assert_revert(
        user_4.tx_with_nonce(
            token_contract.contract_address,
            "unitApprove",
            [user_3.address, *(26, 0), *(2, 0)],
        ),
        reverted_with="ERC3525: caller is not approved for all or not owner of token",
    )


# users   [  1 |   2  |   3   |   1   |  1 |  1  ]
# units   [  2 |   0  |   0   |   0   |  1 |  2  ]
# slot    [ 1  |   2  |   1   |   1   |  1 |  1  ]
# tokens  [ 1  | 2-11 | 12-21 | 22-24 | 25 |  26 ]
@pytest.mark.asyncio
async def test_merge(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    token_12 = (12, 0)
    token_22 = (22, 0)
    token_23 = (23, 0)
    token_24 = (24, 0)
    token_25 = (25, 0)
    token_26 = (26, 0)

    token_arr = [token_22, token_23, token_24, token_25]
    bad_arr1 = [token_22, token_26, token_24, token_25]
    bad_arr2 = [token_22, token_12, token_24, token_25]

    # check reverts
    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "merge",
            [len(bad_arr1), *unpack_tpl(bad_arr1), *token_26],
        ),
        reverted_with="ERC3525: tokenIds in array cannot be targetTokenId",
    )

    await assert_revert(
        user_1.tx_with_nonce(
            token_contract.contract_address,
            "merge",
            [len(bad_arr2), *unpack_tpl(bad_arr2), *token_26],
        ),
        reverted_with="ERC3525: owner of target token has to be the same as tokenId",
    )

    tx_info_1 = await user_1.tx_with_nonce(
        token_contract.contract_address,
        "merge",
        [len(token_arr), *unpack_tpl(token_arr), *token_26],
    )
    # check balance
    bal = await token_contract.balanceOf(user_1.address).call()
    assert bal.result == ((2, 0),)
    # check units
    units = await token_contract.unitsInToken(token_26).call()
    assert units.result == ((7, 0),)
    # check supply
    sup = await token_contract.totalSupply().call()
    assert sup.result == ((22, 0),)
    # check slot balance should be
    sup1 = await token_contract.supplyOfSlot(slot_1).call()
    assert sup1.result == ((12, 0),)
    # check owner
    own26 = await token_contract.ownerOf((26, 0)).call()
    assert own26.result == (user_1.address,)

    # check events
    # assert_event_emitted(
    #    tx_info_1,
    #    order=2,
    #    from_address=token_contract.contract_address,
    #    name="Merge",
    #    data=[user_1.address, *(24, 0), *(26, 0), *(1, 0)],
    # )
    # assert_event_emitted(
    #    tx_info_1,
    #    from_address=token_contract.contract_address,
    #    name="Transfer",
    #    data=[user_1.address, 0, *(25, 0)],
    # )


# users   [  1 |   2  |   3   |   B   |  1  ]
# units   [  2 |   0  |   0   |   B   |  7  ]
# slot    [ 1  |   2  |   1   |   1   |  1  ]
# tokens  [ 1  | 2-11 | 12-21 | 22-25 |  26 ]
@pytest.mark.asyncio
async def test_transferUnits(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_3 = accounts[2]
    user_4 = accounts[3]
    token_26 = (26, 0)
    token_12 = (12, 0)
    token_1 = (1, 0)

    # check revert
    await assert_revert(
        user_4.tx_with_nonce(
            token_contract.contract_address,
            "unitTransferFrom",
            [user_1.address, user_3.address, *token_26, *token_12, *(2, 0)],
        ),
        reverted_with="ERC3525: units to transfer exceeds ammount approved",
    )

    # check if approve operator can transfer
    # transfer 1 unit from token 26 -> 12
    tx_info_1 = await user_3.tx_with_nonce(
        token_contract.contract_address,
        "unitTransferFrom",
        [user_1.address, user_3.address, *token_26, *token_12, *(1, 0)],
    )

    # check if owner can transfer
    # transfer 5 units from token 26 -> 1
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "unitTransferFrom",
        [user_1.address, user_1.address, *token_26, *token_1, *(5, 0)],
    )

    # check units
    units1 = await token_contract.unitsInToken(token_1).call()
    units12 = await token_contract.unitsInToken(token_12).call()
    units26 = await token_contract.unitsInToken(token_26).call()
    assert units1.result == ((7, 0),)
    assert units12.result == ((1, 0),)
    assert units26.result == ((1, 0),)

    # check allowance change
    allowance = await token_contract.allowance(token_26, user_3.address).call()
    assert allowance.result == ((1, 0),)

    # check event emmited
    # assert_event_emitted(
    #    tx_info_1,
    #    from_address=token_contract.contract_address,
    #    name="TransferUnits",
    #    data=[user_1.address, user_3.address, *token_26, *token_12, *(1, 0)],
    # )


# users   [  1 |   2  |  3  |   3   |   B   |  1  ]
# units   [  7 |   0  |  1  |   0   |   B   |  1  ]
# slot    [ 1  |   2  |  1  |   1   |   1   |  1  ]
# tokens  [ 1  | 2-11 | 12  | 13-21 | 22-25 |  26 ]
@pytest.mark.asyncio
async def test_transfer(contract_factory):
    _, accounts, token_contract = contract_factory
    user_1 = accounts[0]
    user_2 = accounts[1]
    user_3 = accounts[2]
    user_4 = accounts[3]

    token_2 = (2, 0)
    token_10 = (10, 0)
    token_21 = (21, 0)
    token_26 = (26, 0)

    # transfer 1st in batch
    await user_2.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_2.address, user_1.address, *token_2],
    )
    # transfer last in batch
    await user_3.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_3.address, user_2.address, *token_21],
    )
    # transfer middle in batch
    await user_2.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_2.address, user_3.address, *token_10],
    )
    # transfer not in batch
    await user_1.tx_with_nonce(
        token_contract.contract_address,
        "transferFrom",
        [user_1.address, user_3.address, *token_26],
    )

    # check balance
    bal1 = await token_contract.balanceOf(user_1.address).call()
    assert bal1.result == ((2, 0),)
    bal2 = await token_contract.balanceOf(user_2.address).call()
    assert bal2.result == ((9, 0),)
    bal3 = await token_contract.balanceOf(user_3.address).call()
    assert bal3.result == ((11, 0),)

    # check clear approvals
    allowance1 = await token_contract.allowance(token_26, user_3.address).call()
    assert allowance1.result == ((0, 0),)

    allowance2 = await token_contract.allowance(token_26, user_4.address).call()
    assert allowance2.result == ((0, 0),)


# users   [  1 | 1 |  2  |  3 |  2 |  3  |   3   |  2 |   B   |  3  ]
# units   [  7 | 0 |  0  |  0 |  0 |  1  |   0   |  0 |   B   |  1  ]
# slot    [ 1  | 2 |  2  |  2 |  2 |  1  |   1   |  1 |   1   |  1  ]
# tokens  [ 1  | 2 | 3-9 | 10 | 11 | 12  | 13-20 | 21 | 22-25 |  26 ]
@pytest.mark.asyncio
async def test_finding_slot(contract_factory):
    _, _, token_contract = contract_factory
    # concise
    # users   [  1 |   2  |   3   ]
    # units   [ 10 |   0  |   0   ]
    # slot    [ 1  |   2  |   1   ]
    # tokens  [ 1  | 2-11 | 12-26 ]

    # check slot balance should be
    sup1 = await token_contract.supplyOfSlot(slot_1).call()
    assert sup1.result == ((12, 0),)
    sup2 = await token_contract.supplyOfSlot(slot_2).call()
    assert sup2.result == ((10, 0),)

    # check slotOf
    # check not in batch
    _slot1 = await token_contract.slotOf((1, 0)).call()
    assert _slot1.result == (slot_1,)

    # first in batch
    _slot2 = await token_contract.slotOf((12, 0)).call()
    assert _slot2.result == (slot_1,)

    # check middle of batch
    _slot3 = await token_contract.slotOf((17, 0)).call()
    assert _slot3.result == (slot_1,)
    _slot4 = await token_contract.slotOf((9, 0)).call()
    assert _slot4.result == (slot_2,)

    # check last in batch
    _slot5 = await token_contract.slotOf((26, 0)).call()
    assert _slot5.result == (slot_1,)

    # check slot index of
    index1 = await token_contract.tokenOfSlotByIndex(slot_1, (0, 0)).call()  # token 1
    index2 = await token_contract.tokenOfSlotByIndex(slot_1, (1, 0)).call()  # token 12
    index3 = await token_contract.tokenOfSlotByIndex(slot_1, (10, 0)).call()  # token 21
    index4 = await token_contract.tokenOfSlotByIndex(slot_1, (11, 0)).call()  # token 26
    index5 = await token_contract.tokenOfSlotByIndex(slot_2, (5, 0)).call()  # token 7

    assert index1.result == ((1, 0),)
    assert index2.result == ((12, 0),)
    assert index3.result == ((21, 0),)
    assert index4.result == ((26, 0),)
    assert index5.result == ((7, 0),)
