import os
import pytest
import pytest_asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.openzepplin.utils import str_to_felt, assert_revert, assert_event_emitted
from utils.argHandler import to_starknet_args, eth_to_felt, felt_to_ascii, ascii_to_felt

# from utils.accounts_utils import Account

# The path to the contract source code.
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")
MOCK_FILE = os.path.join(
    "Seraphlabs", "contracts", "mocks", "strings", "asciiEncode_test.cairo"
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
async def test_interger_conversion(contract_factory):
    _, accounts, test_contract = contract_factory

    num = eth_to_felt(1020)
    ascii_num = ascii_to_felt(str(num))

    res1 = await test_contract.return_ascii_interger(int(num)).call()
    assert res1.result == (ascii_num,)