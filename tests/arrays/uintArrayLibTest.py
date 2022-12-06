import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert, assert_event_emitted
from utils.seraphlabs.argHandler import (
    unpack_tpl,
    arr_res,
    string_to_ascii_arr,
    to_starknet_args,
)

# from utils.accounts_utils import Account

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join(
    "Seraphlabs", "contracts", "mocks", "arrays", "uint_array_library_test.cairo"
)

FAKE_PKEY = 123456789987654321
NUM_OF_ACC = 1


@pytest_asyncio.fixture(scope="module")
async def account_factory():
    starknet = await Starknet.empty()
    accounts = []
    # for i in range(NUM_OF_ACC):
    #    account = Account(FAKE_PKEY + i)
    #    await account.create(starknet)
    #    accounts.append(account)
    #    print(f"Account {i} initalized: {account}")
    return starknet, accounts


@pytest_asyncio.fixture(scope="module")
async def contract_factory(account_factory):
    starknet, accounts = account_factory
    test_contract = await starknet.deploy(source=MOCK_FILE)
    return starknet, accounts, test_contract


@pytest.mark.asyncio
async def test_create(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr = [(1, 3)]
    res1 = await test_contract.createArr((1, 3)).call()
    assert res1.result == ((test_arr),)


@pytest.mark.asyncio
async def test_concat(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr1 = [(1, 0), (2, 0), (3, 0)]
    test_arr2 = [(0, 4), (5, 1), (6, 0)]
    res_arr = [(1, 0), (2, 0), (3, 0), (0, 4), (5, 1), (6, 0)]
    res1 = await test_contract.concatUints(test_arr1, test_arr2).call()
    assert res1.result == ((res_arr),)


@pytest.mark.asyncio
async def test_reverse(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr1 = [(1, 0), (2, 0), (3, 0)]
    test_arr2 = [(3, 0), (2, 0), (1, 0)]
    res1 = await test_contract.reverseUints(test_arr1).call()
    assert res1.result == ((test_arr2),)


@pytest.mark.asyncio
async def test_remove_remove_array_of_uints_1(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr = [(1, 0), (2, 0), (4, 0), (4, 4), (0, 0), (3, 0), (4, 0), (5, 0), (6, 0)]
    remove_arr = [(0, 0), (4, 0), (5, 0), (4, 4), (6, 0)]
    res_arr = [(1, 0), (2, 0), (3, 0)]
    res1 = await test_contract.removeArrayOfUints(test_arr, remove_arr).call()
    assert res1.result == ((res_arr),)


@pytest.mark.asyncio
async def test_remove_remove_array_of_uints_2(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr = [(0, 0), (0, 0), (0, 0), (0, 0)]
    remove_arr = [(0, 0)]
    res_arr = []
    res1 = await test_contract.removeArrayOfUints(test_arr, remove_arr).call()
    assert res1.result == ((res_arr),)
