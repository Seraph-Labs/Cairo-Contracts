import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert, assert_event_emitted
from utils.argHandler import unpack_tpl, arr_res, string_to_ascii_arr, to_starknet_args
from utils.accounts_utils import Account

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join("Seraphlabs", "contracts", "mocks", "array_library_test.cairo")

FAKE_PKEY = 123456789987654321
NUM_OF_ACC = 1


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
    test_contract = await starknet.deploy(source=MOCK_FILE)
    return starknet, accounts, test_contract


@pytest.mark.asyncio
async def test_ascending(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr = [1, 2, 3, 4, 5]
    res1 = await test_contract.getAscendingArray(5).call()
    assert res1.result == ((test_arr),)


@pytest.mark.asyncio
async def test_descending(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr = [5, 4, 3, 2, 1]
    res1 = await test_contract.getDescendingArray(5).call()
    assert res1.result == ((test_arr),)


@pytest.mark.asyncio
async def test_remove_remove_array_of_items(contract_factory):
    _, accounts, test_contract = contract_factory
    test_arr1 = [1, 2, 3, 2, 4, 5, 6, 2, 7, 8, 7, 9, 10]
    remove_arr = [2, 5, 7]
    test_arr2 = [1, 3, 4, 6, 8, 9, 10]
    res1 = await test_contract.removeArrayOfItems(test_arr1, remove_arr).call()
    assert res1.result == ((test_arr2),)
