import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert, assert_event_emitted
from utils.argHandler import unpack_tpl, arr_res, string_to_ascii_arr, to_starknet_args

# from utils.accounts_utils import Account

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join(
    "Seraphlabs", "contracts", "mocks", "math", "time_library_test.cairo"
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
async def test_DHMS_format(contract_factory):
    _, accounts, test_contract = contract_factory
    data = (3 * 86400) + (25 * 3600) + (70 * 60) + 40
    res1 = await test_contract.format_DHMS(data).call()
    assert res1.result == (4, 2, 10, 40)


@pytest.mark.asyncio
async def test_Y_format(contract_factory):
    _, accounts, test_contract = contract_factory
    data = 29030400 * 4
    data_2 = 2419200 * 2
    res1 = await test_contract.format_Y(data + data_2).call()
    res2 = await test_contract.format_Y(data_2).call()
    assert res1.result == (4, data_2)
    assert res2.result == (0, data_2)


@pytest.mark.asyncio
async def test_M_format(contract_factory):
    _, accounts, test_contract = contract_factory
    data = 29030400 * 4
    data_2 = 604800 * 2
    res1 = await test_contract.format_M(data + data_2).call()
    res2 = await test_contract.format_M(data_2).call()
    assert res1.result == (48, data_2)
    assert res2.result == (0, data_2)


@pytest.mark.asyncio
async def test_W_format(contract_factory):
    _, accounts, test_contract = contract_factory
    data = 29030400 * 4
    data_2 = 86400 * 2
    res1 = await test_contract.format_W(data + data_2).call()
    res2 = await test_contract.format_W(data_2).call()
    assert res1.result == (192, data_2)
    assert res2.result == (0, data_2)
