""" used to manage accounts and does easier signing"""
import os
from utils.openzepplin.mock_signer import MockSigner
from utils.openzepplin.utils import get_contract_class
from starkware.crypto.signature.signature import pedersen_hash

# locate the path of account contract
ACCOUNT_FILE = os.path.join("SeraphLabs", "contracts", "Account.cairo")


class Account:
    def __init__(self, private_key):
        self.signer = MockSigner(private_key)
        self.contract = None
        self.address = 0
        self.public_key = 0

    # call right after instantiating Account class by puting in the empty starknet object as the argument
    # automatically deploys the account contract and assign __init__ variables
    async def create(self, starknet):
        self.public_key = self.signer.public_key
        contract = await starknet.deploy(
            ACCOUNT_FILE, constructor_calldata=[self.public_key]
        )
        self.contract = contract
        self.address = contract.contract_address

    # automatically send transaction and increases nonce
    async def tx_with_nonce(self, to, selector_name, calldata):
        return await self.signer.send_transaction(
            self.contract, to, selector_name, calldata
        )

    async def batch_tx(self, calls):
        return await self.signer.send_transactions(self.contract, calls)

    # hashes 2 variables and signs it returning sig_r and sig_s
    def hash_and_sign(self, x, y):
        msg_hash = pedersen_hash(x, y)
        # Testsigner init has another Signer class
        return self.signer.signer.sign(msg_hash)
