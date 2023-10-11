use seraphlabs::tokens::tests::mocks::erc3525_mock::{
    ERC3525Mock as Mock, IERC3525MockDispatcher, IERC3525MockDispatcherTrait
};
use seraphlabs::tokens::tests::mocks::receivers_mock::{
    Mock3525Receiver as Receiver, Mock3525InvalidReceiver as InvalidReceiver
};
use seraphlabs::tokens::erc3525::ERC3525Component;
use seraphlabs::tokens::erc721::ERC721Component;
use seraphlabs::tokens::constants;
use seraphlabs::utils::testing::{vars, helper};
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, pop_log, pop_log_raw};
use debug::PrintTrait;

const VALUE_DECIMALS: u8 = 18;

#[inline(always)]
fn RECEIVER() -> ContractAddress {
    helper::deploy(Receiver::TEST_CLASS_HASH, ArrayTrait::new())
}

#[inline(always)]
fn INVALID_RECEIVER() -> ContractAddress {
    helper::deploy(InvalidReceiver::TEST_CLASS_HASH, ArrayTrait::new())
}

#[inline(always)]
fn setup() -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    Serde::serialize(@VALUE_DECIMALS, ref calldata);
    helper::deploy(Mock::TEST_CLASS_HASH, calldata)
}

#[test]
#[available_gas(2000000)]
fn test_constructor() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    assert(mock.value_decimals() == VALUE_DECIMALS, 'invalid value decimals');
    assert(mock.supports_interface(constants::IERC721_ID), 'missing 721 interface ID');
    assert(
        mock.supports_interface(constants::IERC721_ENUMERABLE_ID), 'missing 721 enum interface ID'
    );
    assert(mock.supports_interface(constants::IERC3525_ID), 'missing 3525interface ID');
}

#[test]
#[available_gas(200000000)]
fn test_3525_mint() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let slot_id = 3525;
    let value = 10;

    mock.mint(owner, 1, 0, value);
    mock.mint(owner, 2, slot_id, 0);
    assert(mock.balance_of(owner) == 2, 'invalid balance');
    assert(mock.owner_of(1) == owner, 'wrong owner 1');
    assert(mock.owner_of(2) == owner, 'wrong owner 2');
    assert(mock.token_of_owner_by_index(owner, 0) == 1, 'wrong token 1');
    assert(mock.token_of_owner_by_index(owner, 1) == 2, 'wrong token 2');
    assert(mock.slot_of(1) == 0, 'wrong slot 1');
    assert(mock.slot_of(2) == slot_id, 'wrong slot 2');
    assert(mock.value_of(1) == value, 'wrong value 1');
    assert(mock.value_of(2) == 0, 'wrong value 2');
    // test events
    assert_transfer_event(mock_address, Zeroable::zero(), owner, 1);
    assert_slot_changed_event(mock_address, 1, Zeroable::zero(), Zeroable::zero());
    assert_transfer_value_event(mock_address, Zeroable::zero(), 1, value);
    assert_transfer_event(mock_address, Zeroable::zero(), owner, 2);
    assert_slot_changed_event(mock_address, 2, Zeroable::zero(), slot_id);
    assert_transfer_value_event(mock_address, Zeroable::zero(), 2, 0);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(200000000)]
fn test_approve_value() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let user = vars::USER();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value_1 = 10;
    let value_2 = 20;

    mock.mint(owner, token_id, slot_id, value_1);
    // drop 3 events from the mint function
    helper::drop_events(mock_address, 3);
    // set caller address to owner
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, operator, value_1);
    mock.approve_value(token_id, user, value_2);
    assert(mock.allowance(token_id, operator) == value_1, 'wrong allowance');
    assert(mock.allowance(token_id, user) == value_2, 'wrong allowance');
    // test events
    assert_approval_value_event(mock_address, token_id, operator, value_1);
    assert_approval_value_event(mock_address, token_id, user, value_2);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(200000000)]
fn test_operator_approve_value() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value = 10;

    mock.mint(owner, token_id, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // approve for all
    mock.set_approval_for_all(operator, true);
    // drop 4 events from the mint and approve for all functions
    helper::drop_events(mock_address, 4);
    // set caller address to operator
    set_contract_address(operator);
    // approve value
    mock.approve_value(token_id, operator, value);
    assert(mock.allowance(token_id, operator) == value, 'wrong allowance');
    // test events
    assert_approval_value_event(mock_address, token_id, operator, value);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: invalid caller', 'ENTRYPOINT_FAILED'))]
fn test_approve_value_invalid_caller() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value = 10;

    mock.mint(owner, token_id, slot_id, value);
    // approve value
    mock.approve_value(token_id, operator, value);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: invalid operator', 'ENTRYPOINT_FAILED'))]
fn test_approve_value_invalid_operator() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::INVALID_ADDRESS();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value = 10;

    mock.mint(owner, token_id, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, operator, value);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: approval to owner', 'ENTRYPOINT_FAILED'))]
fn test_approve_value_to_self() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value = 10;

    mock.mint(owner, token_id, slot_id, value);
    // set caller address to operator
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, owner, value);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: caller not approved', 'ENTRYPOINT_FAILED'))]
fn test_approve_value_unapproved_caller() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value = 10;

    mock.mint(owner, token_id, slot_id, value);
    // set caller address to operator
    set_contract_address(operator);
    // approve value
    mock.approve_value(token_id, operator, value);
}

// transfer value from to someone who already has a token with the same slot
#[test]
#[available_gas(200000000)]
fn test_transfer_value_from_1() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 1;
    let token_id_2 = 200;

    mock.mint(owner, token_id_1, slot_id, 40);
    mock.mint(receiver, token_id_2, slot_id, 10);
    // drop 6 events from the 2 mint functions
    helper::drop_events(mock_address, 6);
    // set caller address to owner
    set_contract_address(owner);
    // transfer value
    let res = mock.transfer_value_from(token_id_1, receiver, 40);
    assert(res == token_id_2, 'wrong returned token id');
    assert(mock.slot_of(token_id_1) == slot_id, 'wrong slot 1');
    assert(mock.slot_of(token_id_2) == slot_id, 'wrong slot 2');
    assert(mock.value_of(token_id_1) == 0, 'wrong value 1');
    assert(mock.value_of(token_id_2) == 50, 'wrong value 2');
    // test events
    assert_transfer_value_event(mock_address, token_id_1, token_id_2, 40);
    helper::assert_no_events_left(mock_address);
}

// transfer value from to someone who does not have token with the same slot
#[test]
#[available_gas(200000000)]
fn test_transfer_value_from_2() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 200;
    let token_id_2 = 1;

    mock.mint(owner, token_id_1, slot_id, 40);
    // mint on a different slot for testing purpiose
    mock.mint(receiver, token_id_2, 10, 10);
    // drop 6 events from the 2 mint functions
    helper::drop_events(mock_address, 6);
    // set caller address to owner
    set_contract_address(owner);
    // transfer value
    let res = mock.transfer_value_from(token_id_1, receiver, 10);
    assert(mock.balance_of(owner) == 1, 'invalid balance');
    assert(mock.balance_of(receiver) == 2, 'invalid balance');
    assert(mock.owner_of(res) == receiver, 'wrong owner');
    assert(mock.token_of_owner_by_index(receiver, 0) == token_id_2, 'wrong token 1');
    assert(mock.token_of_owner_by_index(receiver, 1) == res, 'wrong token 2');
    assert(res == token_id_1 + 1, 'wrong returned token id');
    assert(mock.slot_of(token_id_1) == slot_id, 'wrong slot 1');
    assert(mock.slot_of(res) == slot_id, 'wrong slot 2');
    assert(mock.value_of(token_id_1) == 30, 'wrong value 1');
    assert(mock.value_of(res) == 10, 'wrong value 2');
    // test events
    assert_transfer_event(mock_address, Zeroable::zero(), receiver, res);
    assert_slot_changed_event(mock_address, res, Zeroable::zero(), slot_id);
    assert_transfer_value_event(mock_address, Zeroable::zero(), res, 0);
    assert_transfer_value_event(mock_address, token_id_1, res, 10);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: invalid value', 'ENTRYPOINT_FAILED'))]
fn test_transfer_value_from_invalid_value() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 1;
    let token_id_2 = 200;

    mock.mint(owner, token_id_1, slot_id, 40);
    mock.mint(receiver, token_id_2, slot_id, 10);
    // set caller address to owner
    set_contract_address(owner);
    // transfer value
    mock.transfer_value_from(token_id_1, receiver, 0);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: invalid caller', 'ENTRYPOINT_FAILED'))]
fn test_transfer_value_from_invalid_caller() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 1;
    let token_id_2 = 200;

    mock.mint(owner, token_id_1, slot_id, 40);
    mock.mint(receiver, token_id_2, slot_id, 10);
    // transfer value
    mock.transfer_value_from(token_id_1, receiver, 10);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: insufficient allowance', 'ENTRYPOINT_FAILED'))]
fn test_transfer_value_from_unapproved_caller() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 1;
    let token_id_2 = 200;

    mock.mint(owner, token_id_1, slot_id, 40);
    mock.mint(receiver, token_id_2, slot_id, 10);
    // set caller address to owner
    set_contract_address(receiver);
    // transfer value
    mock.transfer_value_from(token_id_1, receiver, 10);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: insufficient balance', 'ENTRYPOINT_FAILED'))]
fn test_transfer_value_from_exceed_balance() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 1;
    let token_id_2 = 200;
    let value = 10;
    mock.mint(owner, token_id_1, slot_id, value);
    mock.mint(receiver, token_id_2, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // transfer value
    mock.transfer_value_from(token_id_1, receiver, value + 1);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: reciever failed', 'ENTRYPOINT_FAILED'))]
fn test_transfer_value_from_invalid_receiver() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let receiver = INVALID_RECEIVER();
    let owner = vars::OWNER();
    let slot_id = 3525;
    let token_id_1 = 1;
    let token_id_2 = 200;
    let value = 10;
    mock.mint(owner, token_id_1, slot_id, value);
    mock.mint(receiver, token_id_2, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // transfer value
    mock.transfer_value_from(token_id_1, receiver, value);
}

#[test]
#[available_gas(200000000)]
fn test_spend_allowance() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let user = vars::USER();
    let receiver = RECEIVER();
    let slot_id = 3525;
    let token_id = 1;
    let token_id_2 = 2;
    let value = 100;
    let allowance = 50;
    let spent_allowance = 10;

    mock.mint(owner, token_id, slot_id, value);
    mock.mint(receiver, token_id_2, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, user, allowance);
    mock.approve_value(token_id, receiver, allowance);
    // drop 8 events from the mint and approve value functions
    helper::drop_events(mock_address, 8);
    // set caller address to receiver
    set_contract_address(receiver);
    // transfer value
    let res = mock.transfer_value_from(token_id, receiver, spent_allowance);
    assert(mock.allowance(token_id, user) == allowance, 'wrong allowance 1');
    assert(mock.allowance(token_id, receiver) == allowance - spent_allowance, 'wrong allowance 2');
    // test events
    assert_approval_value_event(mock_address, token_id, receiver, allowance - spent_allowance);
}

#[test]
#[available_gas(200000000)]
fn test_token_level_approval_spend_allowance() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let receiver = RECEIVER();
    let slot_id = 3525;
    let token_id = 1;
    let token_id_2 = 2;
    let value = 100;
    let allowance = 50;
    let spent_allowance = 10;

    mock.mint(owner, token_id, slot_id, value);
    mock.mint(receiver, token_id_2, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, receiver, allowance);
    // approve for all 
    mock.set_approval_for_all(receiver, true);
    // set caller address to receiver
    set_contract_address(receiver);
    // transfer value
    let res = mock.transfer_value_from(token_id, receiver, spent_allowance);
    assert(mock.allowance(token_id, receiver) == allowance, 'wrong allowance');
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC3525: insufficient allowance', 'ENTRYPOINT_FAILED'))]
fn test_spend_insufficient_allowance() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let receiver = RECEIVER();
    let slot_id = 3525;
    let token_id = 1;
    let token_id_2 = 2;
    let value = 100;
    let allowance = 50;

    mock.mint(owner, token_id, slot_id, value);
    mock.mint(receiver, token_id_2, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, receiver, allowance);
    // set caller address to receiver
    set_contract_address(receiver);
    // transfer value
    mock.transfer_value_from(token_id, receiver, allowance + 1);
}

#[test]
#[available_gas(200000000)]
fn test_clear_unit_level_approvals() {
    let mock_address = setup();
    let mock = IERC3525MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let user = vars::USER();
    let receiver = RECEIVER();
    let slot_id = 3525;
    let token_id = vars::TOKEN_ID();
    let value = 1000;

    mock.mint(owner, token_id, slot_id, value);
    // set caller address to owner
    set_contract_address(owner);
    // approve value
    mock.approve_value(token_id, operator, value);
    mock.approve_value(token_id, user, value);
    mock.approve_value(token_id, receiver, value);
    // transfer_from token to receiver
    // this function clears the approvals
    mock.transfer_from(owner, receiver, token_id);
    assert(mock.allowance(token_id, operator) == 0, 'wrong allowance 1');
    assert(mock.allowance(token_id, user) == 0, 'wrong allowance 2');
    assert(mock.allowance(token_id, receiver) == 0, 'wrong allowance 3');
}

// -------------------------------------------------------------------------- //
//                              event assertions                              //
// -------------------------------------------------------------------------- //
#[inline(always)]
fn assert_transfer_value_event(
    contract_addr: ContractAddress, from_token_id: u256, to_token_id: u256, value: u256,
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC3525Event(
            ERC3525Component::Event::TransferValue(
                ERC3525Component::TransferValue { from_token_id, to_token_id, value }
            )
        ),
        'Wrong TransferValue Event'
    );
}

#[inline(always)]
fn assert_approval_value_event(
    contract_addr: ContractAddress, token_id: u256, operator: ContractAddress, value: u256,
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC3525Event(
            ERC3525Component::Event::ApprovalValue(
                ERC3525Component::ApprovalValue { token_id, operator, value }
            )
        ),
        'Wrong ApprovalValue Event'
    );
}

#[inline(always)]
fn assert_slot_changed_event(
    contract_addr: ContractAddress, token_id: u256, old_slot: u256, new_slot: u256,
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC3525Event(
            ERC3525Component::Event::SlotChanged(
                ERC3525Component::SlotChanged { token_id, old_slot, new_slot }
            )
        ),
        'Wrong SlotChanged Event'
    );
}

fn assert_transfer_event(
    contract_addr: ContractAddress, from: ContractAddress, to: ContractAddress, token_id: u256
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC721Event(
            ERC721Component::Event::Transfer(ERC721Component::Transfer { from, to, token_id })
        ),
        'Wrong Transfer Event'
    );
}
