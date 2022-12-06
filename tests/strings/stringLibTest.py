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
    "Seraphlabs", "contracts", "mocks", "strings", "string_library_test1.cairo"
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
async def test_word(contract_factory):
    _, accounts, test_contract = contract_factory
    res1 = await test_contract.return_ascii_arr().call()
    assert res1.result == ((string_to_ascii_arr('"hello"')),)


@pytest.mark.asyncio
async def test_json(contract_factory):
    _, accounts, test_contract = contract_factory
    jsontext = '{"name":"BasicSeraph #1", "weapon":"sword"}'
    res1 = await test_contract.get_json().call()
    assert res1.result == ((string_to_ascii_arr(jsontext)),)


@pytest.mark.asyncio
async def test_json_with_uint(contract_factory):
    _, accounts, test_contract = contract_factory
    jsontext = '{"name":"BasicSeraph #2114", "weapon":"sword"}'
    res1 = await test_contract.get_string_with_uint_json().call()
    print("hello")
    assert res1.result == ((string_to_ascii_arr(jsontext)),)


@pytest.mark.asyncio
async def test_json_arr(contract_factory):
    _, accounts, test_contract = contract_factory
    jsontext = '{"name":"BasicSeraph", "weapon":"sword", "attributes":["name":"BasicSeraph", "weapon":"sword", "weapon":"sword"]}'
    res1 = await test_contract.get_string_jsonArr().call()
    assert res1.result == ((string_to_ascii_arr(jsontext)),)


@pytest.mark.asyncio
async def test_doublequote_append(contract_factory):
    _, accounts, test_contract = contract_factory
    text = '"weapon #2114"'
    res1 = await test_contract.test_enclosed_string_append((2114, 0)).call()
    assert res1.result == ((string_to_ascii_arr(text)),)


@pytest.mark.asyncio
async def test_string_equal(contract_factory):
    _, accounts, test_contract = contract_factory
    class1 = dict(val=str_to_felt('"paladin"'), len=9)
    class2 = dict(val=str_to_felt('"crusader"'), len=10)

    res1 = await test_contract.test_stringEqual(
        to_starknet_args(class1), to_starknet_args(class1)
    ).call()
    res2 = await test_contract.test_stringEqual(
        to_starknet_args(class1), to_starknet_args(class2)
    ).call()
    assert res1.result == (1,)
    assert res2.result == (0,)
