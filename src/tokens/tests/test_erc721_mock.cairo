use seraphlabs::tokens::tests::mocks::erc721_mock::{
    ERC721Mock as Mock, IERC721MockDispatcher, IERC721MockDispatcherTrait
};
use seraphlabs::tokens::tests::mocks::receivers_mock::{Mock721Receiver as Receiver, NonReceiver};
use seraphlabs::tokens::erc721::ERC721;
use seraphlabs::tokens::constants;
use seraphlabs::utils::testing::{vars, helper};
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, pop_log, pop_log_raw};
use traits::{Into, TryInto};
use option::OptionTrait;
use array::ArrayTrait;
use core::clone::Clone;
use debug::PrintTrait;

const NAME: felt252 = 'hello';
const SYMBOL: felt252 = 'world';

fn DATA(valid: bool) -> Span<felt252> {
    let mut data = ArrayTrait::<felt252>::new();
    match valid {
        bool::False(()) => data.append('fail'),
        bool::True(()) => data.append('pass'),
    }
    data.span()
}

fn RECEIVER() -> ContractAddress {
    helper::deploy(Receiver::TEST_CLASS_HASH, ArrayTrait::new())
}

fn NON_RECEIVER() -> ContractAddress {
    helper::deploy(NonReceiver::TEST_CLASS_HASH, ArrayTrait::new())
}

fn setup() -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    Serde::serialize(@NAME, ref calldata);
    Serde::serialize(@SYMBOL, ref calldata);
    helper::deploy(Mock::TEST_CLASS_HASH, calldata)
}

#[test]
#[available_gas(2000000)]
fn test_constructor() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    assert(mock.name() == NAME, 'name is not set correctly');
    assert(mock.symbol() == SYMBOL, 'symbol is not set correctly');
    assert(mock.supports_interface(constants::IERC721_ID), 'missing interface ID');
    assert(mock.supports_interface(constants::IERC721_METADATA_ID), 'missing interface ID');
}

#[test]
#[available_gas(2000000)]
fn test_token_uri() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let base_uri = vars::BASEURI();
    let token_id = vars::TOKEN_ID();

    mock.set_base_uri(base_uri.clone());
    mock.mint(vars::OWNER(), token_id);
    let data = mock.token_uri(token_id);
    assert(data.len() == 4, 'base uri is not set correctly');
    assert(*data.at(0) == *base_uri[0], 'base uri is not set correctly');
    assert(*data.at(1) == *base_uri[1], 'base uri is not set correctly');
    assert(*data.at(2) == '2114', 'base uri is not set correctly');
    assert(*data.at(3) == '.json', 'base uri is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721Metadata: invalid tokenId', 'ENTRYPOINT_FAILED'))]
fn test_token_uri_invalid_token_id() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    mock.token_uri(0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_balance_of() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    mock.mint(owner, token_id);
    assert(mock.balance_of(owner) == 1_u256, 'wrong balance');
    assert_transfer_event(mock_address, Zeroable::zero(), owner, token_id);
}

#[test]
#[available_gas(2000000)]
fn test_owner_of() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();

    mock.mint(owner, token_id);
    assert(mock.owner_of(token_id) == owner, 'wrong owner');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', 'ENTRYPOINT_FAILED'))]
fn test_mint_invalid_address() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    mock.mint(vars::INVALID_ADDRESS(), 2114_u256);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: tokenId already exist', 'ENTRYPOINT_FAILED'))]
fn test_mint_existing_token() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();

    mock.mint(owner, token_id);
    mock.mint(owner, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', 'ENTRYPOINT_FAILED'))]
fn test_mint_invalid_token() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    mock.mint(vars::OWNER(), 0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let token_id = vars::TOKEN_ID();

    set_contract_address(owner);

    mock.mint(owner, token_id);
    mock.approve(operator, token_id);
    assert(mock.get_approved(token_id) == operator, 'approved is not set correctly');
    assert_transfer_event(mock_address, Zeroable::zero(), owner, token_id);
    assert_approval_event(mock_address, owner, operator, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid owner', 'ENTRYPOINT_FAILED'))]
fn test_only_owner_approve() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let user = vars::USER();

    set_contract_address(user);

    mock.mint(owner, token_id);
    mock.approve(user, token_id);
}


#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', 'ENTRYPOINT_FAILED'))]
fn test_approve_to_self() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    set_contract_address(owner);

    mock.mint(owner, token_id);
    mock.approve(owner, token_id);
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    set_contract_address(owner);

    mock.set_approval_for_all(operator, true);
    assert(mock.is_approved_for_all(owner, operator), 'approval for all fail');
    assert_approval_for_all_event(mock_address, owner, operator, true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', 'ENTRYPOINT_FAILED'))]
fn test_approval_for_all_invalid_operator() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    set_contract_address(owner);

    mock.set_approval_for_all(vars::INVALID_ADDRESS(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', 'ENTRYPOINT_FAILED'))]
fn test_approval_for_all_invalid_caller() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    set_contract_address(vars::INVALID_ADDRESS());

    mock.set_approval_for_all(vars::OPERATOR(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', 'ENTRYPOINT_FAILED'))]
fn test_approval_for_all_to_self() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    set_contract_address(owner);
    mock.set_approval_for_all(owner, true);
}

#[test]
#[available_gas(200000000)]
fn test_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let user = vars::USER();

    mock.mint(owner, token_id);
    // drop transfer event
    pop_log_raw(mock_address);

    set_contract_address(owner);
    mock.approve(operator, token_id);
    // drop approval event
    pop_log_raw(mock_address);
    mock.transfer_from(owner, user, token_id);
    // test clear approvals
    assert(mock.get_approved(token_id) == vars::INVALID_ADDRESS(), 'approvals not cleared');
    assert(mock.balance_of(owner) == 0_u256, 'balance is not set correctly');
    assert(mock.balance_of(user) == 1_u256, 'balance is not set correctly');
    assert(mock.owner_of(token_id) == user, 'owner is not set correctly');
    // test events
    assert_transfer_event(mock_address, owner, user, token_id);
}

#[test]
#[available_gas(2000000)]
fn test_approve_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();

    set_contract_address(owner);
    // approve tokenId to account 2
    mock.mint(owner, token_id);
    // drop transfer event
    pop_log_raw(mock_address);

    mock.approve(operator, token_id);
    // set caller to account 2
    set_contract_address(operator);
    mock.transfer_from(owner, operator, token_id);

    assert(mock.balance_of(owner) == 0.into(), 'balance is not set correctly');
    assert(mock.balance_of(operator) == 1.into(), 'balance is not set correctly');
    assert(mock.owner_of(token_id) == operator, 'owner is not set correctly');
    // test events
    assert_approval_event(mock_address, owner, operator, token_id);
    assert_transfer_event(mock_address, owner, operator, token_id);
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();

    set_contract_address(owner);
    // approve tokenId to account 2
    mock.mint(owner, token_id);
    // drop transfer event
    pop_log_raw(mock_address);

    mock.set_approval_for_all(operator, true);
    // set caller to account 2
    set_contract_address(operator);
    mock.transfer_from(owner, operator, token_id);

    assert(mock.balance_of(owner) == 0.into(), 'balance is not set correctly');
    assert(mock.balance_of(operator) == 1.into(), 'balance is not set correctly');
    assert(mock.owner_of(token_id) == operator, 'owner is not set correctly');
    // test events
    assert_approval_for_all_event(mock_address, owner, operator, true);
    assert_transfer_event(mock_address, owner, operator, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: caller is not approved', 'ENTRYPOINT_FAILED'))]
fn test_unapproved_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let user = vars::USER();

    mock.mint(owner, token_id);
    set_contract_address(user);

    mock.transfer_from(owner, user, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid sender', 'ENTRYPOINT_FAILED'))]
fn test_invalid_from_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let user = vars::USER();

    mock.mint(owner, token_id);
    set_contract_address(owner);
    mock.transfer_from(user, operator, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', 'ENTRYPOINT_FAILED'))]
fn test_invalid_to_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();

    mock.mint(owner, token_id);
    set_contract_address(owner);
    mock.transfer_from(owner, vars::INVALID_ADDRESS(), token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', 'ENTRYPOINT_FAILED'))]
fn test_invalid_token_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let user = vars::USER();
    set_contract_address(owner);
    mock.transfer_from(owner, user, 0_u256);
}

#[test]
#[available_gas(2000000000)]
fn test_safe_transfer() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let receiver = RECEIVER();

    mock.mint(owner, token_id);
    // drop transfer event
    pop_log_raw(mock_address);

    set_contract_address(owner);
    mock.safe_transfer_from(owner, receiver, token_id, DATA(true));

    assert(mock.balance_of(owner) == 0_u256, 'balance is not set correctly');
    assert(mock.balance_of(receiver) == 1_u256, 'balance is not set correctly');
    assert(mock.owner_of(token_id) == receiver, 'owner is not set correctly');
    // test events
    assert_transfer_event(mock_address, owner, receiver, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: reciever failed', 'ENTRYPOINT_FAILED'))]
fn test_safe_transfer_receiver_fail() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let receiver = RECEIVER();

    mock.mint(owner, token_id);
    set_contract_address(owner);
    mock.safe_transfer_from(owner, receiver, token_id, DATA(false));
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', 'ENTRYPOINT_FAILED'))]
fn test_safe_transfer_non_receiver() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let non_receiver = NON_RECEIVER();
    mock.mint(owner, token_id);
    set_contract_address(owner);
    mock.safe_transfer_from(owner, non_receiver, token_id, DATA(true));
}

#[test]
#[available_gas(2000000)]
fn test_safe_mint() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let receiver = RECEIVER();

    set_contract_address(receiver);
    mock.safe_mint(receiver, token_id, DATA(true));

    assert(mock.balance_of(receiver) == 1_u256, 'balance is not set correctly');
    assert(mock.owner_of(token_id) == receiver, 'owner is not set correctly');
    // test events
    assert_transfer_event(mock_address, Zeroable::zero(), receiver, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: reciever failed', 'ENTRYPOINT_FAILED'))]
fn test_safe_mint_receiver_fail() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let receiver = RECEIVER();

    set_contract_address(receiver);
    mock.safe_mint(receiver, token_id, DATA(false));
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', 'ENTRYPOINT_FAILED'))]
fn safe_mint_non_receiver() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let non_receiver = NON_RECEIVER();

    set_contract_address(non_receiver);
    mock.safe_mint(non_receiver, token_id, DATA(true));
}

#[test]
#[available_gas(2000000)]
fn test_burn() {
    let mock_address = setup();
    let mock = IERC721MockDispatcher { contract_address: mock_address };

    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    set_contract_address(owner);

    mock.mint(owner, token_id);
    // drop transfer event
    pop_log_raw(mock_address);

    mock.burn(token_id);
    assert(mock.balance_of(owner) == 0_u256, 'balance is not set correctly');
    // test events
    assert_transfer_event(mock_address, owner, Zeroable::zero(), token_id);
}

fn assert_transfer_event(
    contract_addr: ContractAddress, from: ContractAddress, to: ContractAddress, token_id: u256
) {
    let event = pop_log::<ERC721::Event>(contract_addr).unwrap();
    assert(
        event == ERC721::Event::Transfer(ERC721::Transfer { from, to, token_id }),
        'Wrong Transfer Event'
    );
}

fn assert_approval_event(
    contract_addr: ContractAddress,
    owner: ContractAddress,
    approved: ContractAddress,
    token_id: u256
) {
    let event = pop_log::<ERC721::Event>(contract_addr).unwrap();
    assert(
        event == ERC721::Event::Approval(ERC721::Approval { owner, approved, token_id }),
        'Wrong Approval Event'
    );
}

fn assert_approval_for_all_event(
    contract_addr: ContractAddress,
    owner: ContractAddress,
    operator: ContractAddress,
    approved: bool
) {
    let event = pop_log::<ERC721::Event>(contract_addr).unwrap();
    assert(
        event == ERC721::Event::ApprovalForAll(
            ERC721::ApprovalForAll { owner, operator, approved }
        ),
        'Wrong ApprovalForAll Event'
    );
}
