use seraphlabs::tokens::tests::mocks::trait_catalog_mock::TraitCatalogMock as Mock;
use seraphlabs::tokens::erc2114::extensions::TraitCatalogComponent;
use seraphlabs::tokens::erc2114::interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
use seraphlabs::tokens::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
use seraphlabs::tokens::constants;
use seraphlabs::utils::testing::{vars, helper};
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, pop_log, pop_log_raw};
use debug::PrintTrait;

fn setup() -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    helper::deploy(Mock::TEST_CLASS_HASH, calldata)
}

#[test]
#[available_gas(2000000)]
fn test_constructor() {
    let mock_address = setup();
    let mock = ISRC5Dispatcher { contract_address: mock_address };
    assert(mock.supports_interface(constants::ITRAIT_CATALOG_ID), 'wrong Interface ID');
}


#[test]
#[available_gas(2000000000)]
fn test_generate_trait_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values_1 = array!['fire', 'water', 'grass'].span();
    let values_2 = array!['normal', 'fighting'].span();
    mock.generate_trait_list(values_1);
    mock.generate_trait_list(values_2);

    assert(mock.trait_list_count() == 2, 'wrong trait list count');
    assert(mock.trait_list_length(1) == 3, 'wrong trait list length');
    assert(mock.trait_list_length(2) == 2, 'wrong trait list length');

    assert(mock.trait_list_value_by_index(1, 0) == 0, 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 1) == 'fire', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 2) == 'water', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 3) == 'grass', 'wrong trait list value');

    assert(mock.trait_list_value_by_index(2, 0) == 0, 'wrong trait list value');
    assert(mock.trait_list_value_by_index(2, 1) == 'normal', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(2, 2) == 'fighting', 'wrong trait list value');
    // test events
    assert_trait_list_update_event(mock_address, 1, 1, 0, 'fire');
    assert_trait_list_update_event(mock_address, 1, 2, 0, 'water');
    assert_trait_list_update_event(mock_address, 1, 3, 0, 'grass');
    assert_trait_list_update_event(mock_address, 2, 1, 0, 'normal');
    assert_trait_list_update_event(mock_address, 2, 2, 0, 'fighting');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid values', 'ENTRYPOINT_FAILED'))]
fn test_generate_trait_list_empty_values() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array![].span();
    mock.generate_trait_list(values);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid update', 'ENTRYPOINT_FAILED'))]
fn test_generate_trait_list_invalid_values() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 0, 'grass'].span();
    mock.generate_trait_list(values);
}

#[test]
#[available_gas(2000000)]
fn test_append_to_trait_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water'].span();
    mock.generate_trait_list(values);
    mock.append_to_trait_list(1, 'grass');

    assert(mock.trait_list_count() == 1, 'wrong trait list count');
    assert(mock.trait_list_length(1) == 3, 'wrong trait list length');

    assert(mock.trait_list_value_by_index(1, 0) == 0, 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 1) == 'fire', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 2) == 'water', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 3) == 'grass', 'wrong trait list value');

    // test events
    assert_trait_list_update_event(mock_address, 1, 1, 0, 'fire');
    assert_trait_list_update_event(mock_address, 1, 2, 0, 'water');
    assert_trait_list_update_event(mock_address, 1, 3, 0, 'grass');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid list id', 'ENTRYPOINT_FAILED'))]
fn test_append_to_non_existant_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    mock.append_to_trait_list(1, 'grass');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid list id', 'ENTRYPOINT_FAILED'))]
fn test_append_to_zero_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water'].span();
    mock.generate_trait_list(values);
    mock.append_to_trait_list(0, 'grass');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid update', 'ENTRYPOINT_FAILED'))]
fn test_append_invalid_value() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water'].span();
    mock.generate_trait_list(values);
    mock.append_to_trait_list(1, 0);
}


#[test]
#[available_gas(2000000)]
fn test_append_batch_to_trait_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire'].span();
    mock.generate_trait_list(values);
    mock.append_batch_to_trait_list(1, array!['water', 'grass'].span());

    assert(mock.trait_list_count() == 1, 'wrong trait list count');
    assert(mock.trait_list_length(1) == 3, 'wrong trait list length');

    assert(mock.trait_list_value_by_index(1, 0) == 0, 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 1) == 'fire', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 2) == 'water', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 3) == 'grass', 'wrong trait list value');

    // test events
    assert_trait_list_update_event(mock_address, 1, 1, 0, 'fire');
    assert_trait_list_update_event(mock_address, 1, 2, 0, 'water');
    assert_trait_list_update_event(mock_address, 1, 3, 0, 'grass');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid values', 'ENTRYPOINT_FAILED'))]
fn test_append_batch_to_trait_list_empty_values() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire'].span();
    mock.generate_trait_list(values);
    mock.append_batch_to_trait_list(1, array![].span());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid update', 'ENTRYPOINT_FAILED'))]
fn test_append_batch_with_invalid_values() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire'].span();
    mock.generate_trait_list(values);
    mock.append_batch_to_trait_list(1, array!['water', 0].span());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid list id', 'ENTRYPOINT_FAILED'))]
fn test_append_batch_to_non_existant_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    mock.append_batch_to_trait_list(1, array!['fire'].span());
}

#[test]
#[available_gas(2000000)]
fn test_ammend_trait_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water', 'grass'].span();
    mock.generate_trait_list(values);
    // drop events from generate_list
    pop_log_raw(mock_address);
    pop_log_raw(mock_address);
    pop_log_raw(mock_address);

    mock.ammend_trait_list(1, 2, 'electric');
    assert(mock.trait_list_count() == 1, 'wrong trait list count');
    assert(mock.trait_list_length(1) == 3, 'wrong trait list length');

    assert(mock.trait_list_value_by_index(1, 0) == 0, 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 1) == 'fire', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 2) == 'electric', 'wrong trait list value');
    assert(mock.trait_list_value_by_index(1, 3) == 'grass', 'wrong trait list value');

    // test events
    assert_trait_list_update_event(mock_address, 1, 2, 'water', 'electric');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid list id', 'ENTRYPOINT_FAILED'))]
fn test_ammend_non_existant_list() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water', 'grass'].span();
    mock.generate_trait_list(values);
    mock.ammend_trait_list(2, 1, 'electric');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid update', 'ENTRYPOINT_FAILED'))]
fn test_ammend_zero_index() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water', 'grass'].span();
    mock.generate_trait_list(values);
    mock.ammend_trait_list(1, 0, 'electric');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: index exceeded', 'ENTRYPOINT_FAILED'))]
fn test_ammend_out_of_bounds_index() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water', 'grass'].span();
    mock.generate_trait_list(values);
    mock.ammend_trait_list(1, 4, 'electric');
}


#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('TraitCatalog: invalid update', 'ENTRYPOINT_FAILED'))]
fn test_ammend_invalid_value() {
    let mock_address = setup();
    let mock = ITraitCatalogDispatcher { contract_address: mock_address };

    let values = array!['fire', 'water', 'grass'].span();
    mock.generate_trait_list(values);
    mock.ammend_trait_list(1, 2, 0);
}

fn assert_trait_list_update_event(
    contract_addr: ContractAddress,
    list_id: u64,
    index: felt252,
    old_value: felt252,
    new_value: felt252
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::TraitCatalogEvent(
            TraitCatalogComponent::Event::TraitListUpdate(
                TraitCatalogComponent::TraitListUpdate { list_id, index, old_value, new_value, }
            )
        ),
        'wrong trait list update event'
    );
}
