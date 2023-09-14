use seraphlabs::tokens::tests::mocks::erc2114_slot_attr_mock::{
    ERC2114SlotAttrMock as Mock, IERC2114SlotAttrMockDispatcher,
    IERC2114SlotAttrMockDispatcherTrait,
};
use seraphlabs::tokens::erc2114::utils::AttrType;
use seraphlabs::tokens::erc2114::extensions::ERC2114SlotAttribute as ERC2114SlotAttr;
use seraphlabs::tokens::erc721::ERC721;
use seraphlabs::tokens::tests::mocks::trait_catalog_mock::{
    TraitCatalogMock, InvalidTraitCatalogMock
};
use seraphlabs::tokens::erc2114::interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
use seraphlabs::tokens::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
use seraphlabs::tokens::constants;
use seraphlabs::utils::testing::{vars, helper};
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, pop_log, pop_log_raw};
use debug::PrintTrait;

// only used for testing constructor
fn test_setup() -> (ContractAddress, ContractAddress) {
    let trait_cat_calldata = array![];
    let trait_cat_addr = helper::deploy(TraitCatalogMock::TEST_CLASS_HASH, trait_cat_calldata);
    // generate_trait_list
    let trait_catalog = ITraitCatalogDispatcher { contract_address: trait_cat_addr };
    trait_catalog.generate_trait_list(array!['fire', 'water', 'grass'].span());

    set_contract_address(vars::OWNER());
    let mut calldata = array![];
    Serde::serialize(@trait_cat_addr, ref calldata);
    (helper::deploy(Mock::TEST_CLASS_HASH, calldata), trait_cat_addr)
}

fn setup() -> ContractAddress {
    let trait_cat_calldata = array![];
    let trait_cat_addr = helper::deploy(TraitCatalogMock::TEST_CLASS_HASH, trait_cat_calldata);
    // generate_trait_list
    let trait_catalog = ITraitCatalogDispatcher { contract_address: trait_cat_addr };
    trait_catalog.generate_trait_list(array!['fire', 'water', 'grass'].span());

    let mut calldata = array![];
    Serde::serialize(@trait_cat_addr, ref calldata);
    let mock_address = helper::deploy(Mock::TEST_CLASS_HASH, calldata);
    // drop trait catalog attached event
    pop_log_raw(mock_address);
    mock_address
}

#[test]
#[available_gas(2000000)]
fn test_constructor() {
    let (mock_address, trait_cat) = test_setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };

    assert(mock.supports_interface(constants::IERC721_ID), 'no erc721 interface');
    assert(mock.supports_interface(constants::IERC721_ENUMERABLE_ID), 'no erc721 enum interface');
    assert(mock.supports_interface(constants::IERC2114_ID), 'no erc2114 interface');
    assert(
        mock.supports_interface(constants::IERC2114_SLOT_ATTRIBUTE_ID), 'no slot attr interface'
    );
    assert(mock.get_trait_catalog() == trait_cat, 'wrong trait catalog');
}

#[test]
#[available_gas(20000000)]
fn test_set_slot_attribute() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let slot_id = vars::TOKEN_ID();

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(1234, 'type', AttrType::String(1));
    let attr3 = generate_attribute(123, 'rarity', AttrType::Number(4));

    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
    mock.create_attribute(attr3.id, attr3.attr_type, attr3.name);

    helper::drop_events(mock_address, 3);

    mock.set_slot_attribute(slot_id, attr1.id, 'charizard');
    mock.set_slot_attribute(slot_id, attr2.id, 1);
    mock.set_slot_attribute(slot_id, attr3.id, 20);

    assert(
        mock.slot_attributes_of(slot_id) == array![attr1.id, attr2.id, attr3.id].span(),
        'wrong attributes'
    );
    assert(mock.slot_attribute_value(slot_id, attr1.id) == 'charizard', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr2.id) == 'fire', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr3.id) == 20, 'wrong value');

    mock.set_slot_attribute(slot_id, attr1.id, 'blastoise');
    mock.set_slot_attribute(slot_id, attr2.id, 2);
    mock.set_slot_attribute(slot_id, attr3.id, 20);

    assert(
        mock.slot_attributes_of(slot_id) == array![attr1.id, attr2.id, attr3.id].span(),
        'wrong attributes'
    );
    assert(mock.slot_attribute_value(slot_id, attr1.id) == 'blastoise', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr2.id) == 'water', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr3.id) == 20, 'wrong value');

    // test events
    assert_slot_attribute_update_event(
        mock_address, slot_id, attr1.id, attr1.attr_type, 0, 'charizard'
    );
    assert_slot_attribute_update_event(mock_address, slot_id, attr2.id, attr2.attr_type, 0, 1);
    assert_slot_attribute_update_event(mock_address, slot_id, attr3.id, attr3.attr_type, 0, 20);
    assert_slot_attribute_update_event(
        mock_address, slot_id, attr1.id, attr1.attr_type, 'charizard', 'blastoise'
    );
    assert_slot_attribute_update_event(mock_address, slot_id, attr2.id, attr2.attr_type, 1, 2);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(20000000)]
fn test_batch_set_slot_attribute() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let slot_id = vars::TOKEN_ID();

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(1234, 'type', AttrType::String(1));
    let attr3 = generate_attribute(123, 'rarity', AttrType::Number(4));
    let attr4 = generate_attribute(12, 'level', AttrType::Number(0));

    // second set
    let attr5 = generate_attribute(12345, 'trainer', AttrType::String(0));
    let attr6 = generate_attribute(123456, 'nature', AttrType::String(0));

    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
    mock.create_attribute(attr3.id, attr3.attr_type, attr3.name);
    mock.create_attribute(attr4.id, attr4.attr_type, attr4.name);
    mock.create_attribute(attr5.id, attr5.attr_type, attr5.name);
    mock.create_attribute(attr6.id, attr6.attr_type, attr6.name);

    helper::drop_events(mock_address, 6);

    mock
        .batch_set_slot_attribute(
            slot_id,
            array![attr1.id, attr2.id, attr3.id, attr4.id].span(),
            array!['charizard', 1, 20, 100].span()
        );

    assert(
        mock.slot_attributes_of(slot_id) == array![attr1.id, attr2.id, attr3.id, attr4.id].span(),
        'wrong attributes'
    );
    assert(mock.slot_attribute_value(slot_id, attr1.id) == 'charizard', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr2.id) == 'fire', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr3.id) == 20, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr4.id) == 100, 'wrong value');

    mock
        .batch_set_slot_attribute(
            slot_id,
            array![attr1.id, attr5.id, attr2.id, attr3.id, attr6.id].span(),
            array!['blastoise', 'ash', 2, 30, 'timid'].span()
        );

    assert(
        mock
            .slot_attributes_of(
                slot_id
            ) == array![attr1.id, attr2.id, attr3.id, attr4.id, attr5.id, attr6.id]
            .span(),
        'wrong attributes'
    );
    assert(mock.slot_attribute_value(slot_id, attr1.id) == 'blastoise', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr2.id) == 'water', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr3.id) == 30, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr4.id) == 100, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr5.id) == 'ash', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr6.id) == 'timid', 'wrong value');

    // test events
    assert_slot_attribute_update_event(
        mock_address, slot_id, attr1.id, attr1.attr_type, 0, 'charizard'
    );
    assert_slot_attribute_update_event(mock_address, slot_id, attr2.id, attr2.attr_type, 0, 1);
    assert_slot_attribute_update_event(mock_address, slot_id, attr3.id, attr3.attr_type, 0, 20);
    assert_slot_attribute_update_event(mock_address, slot_id, attr4.id, attr4.attr_type, 0, 100);
    assert_slot_attribute_update_event(
        mock_address, slot_id, attr1.id, attr1.attr_type, 'charizard', 'blastoise'
    );
    assert_slot_attribute_update_event(mock_address, slot_id, attr5.id, attr5.attr_type, 0, 'ash');
    assert_slot_attribute_update_event(mock_address, slot_id, attr2.id, attr2.attr_type, 1, 2);
    assert_slot_attribute_update_event(mock_address, slot_id, attr3.id, attr3.attr_type, 20, 30);
    assert_slot_attribute_update_event(
        mock_address, slot_id, attr6.id, attr6.attr_type, 0, 'timid'
    );
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid slot_id', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_attribute_invalid_slot_id() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.set_slot_attribute(0, attr1.id, 'charizard');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id value', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_attribute_zero_value() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let slot_id = vars::TOKEN_ID();

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.set_slot_attribute(slot_id, attr1.id, 0);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id value', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_attribute_invalid_list_index() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let slot_id = vars::TOKEN_ID();

    let attr1 = generate_attribute(1234, 'type', AttrType::String(1));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.set_slot_attribute(slot_id, attr1.id, 4);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_attribute_invalid_attr_id() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let slot_id = vars::TOKEN_ID();

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));

    mock.set_slot_attribute(slot_id, attr1.id, 'charizard');
}

#[test]
#[available_gas(20000000)]
fn test_remove_slot_attribute() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let slot_id = vars::TOKEN_ID();

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(1234, 'type', AttrType::String(1)); //remove 1
    let attr3 = generate_attribute(123, 'rarity', AttrType::Number(4));
    // set 2
    let attr4 = generate_attribute(12, 'boost', AttrType::Number(8)); //remove 2
    let attr5 = generate_attribute(12345, 'trainer', AttrType::String(0)); //remove 4
    // set 3
    let attr6 = generate_attribute(123456, 'nature', AttrType::String(0)); // remove 3 
    let attr7 = generate_attribute(1234567, 'level', AttrType::Number(0));

    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
    mock.create_attribute(attr3.id, attr3.attr_type, attr3.name);
    mock.create_attribute(attr4.id, attr4.attr_type, attr4.name);
    mock.create_attribute(attr5.id, attr5.attr_type, attr5.name);
    mock.create_attribute(attr6.id, attr6.attr_type, attr6.name);
    mock.create_attribute(attr7.id, attr7.attr_type, attr7.name);
    // add first set
    mock
        .batch_set_slot_attribute(
            slot_id, array![attr1.id, attr2.id, attr3.id].span(), array!['charizard', 1, 20].span()
        );
    // add second set
    mock
        .batch_set_slot_attribute(
            slot_id, array![attr4.id, attr5.id].span(), array![1148, 'ash'].span()
        );
    // add third set
    mock
        .batch_set_slot_attribute(
            slot_id, array![attr6.id, attr7.id].span(), array!['timid', 50].span()
        );

    helper::drop_events(mock_address, 14);

    mock
        .remove_attributes_from_slot(
            slot_id, array![attr2.id, attr4.id, attr6.id, attr5.id].span()
        );

    assert(
        mock.slot_attributes_of(slot_id) == array![attr1.id, attr3.id, attr7.id].span(),
        'wrong attributes'
    );
    assert(mock.slot_attribute_value(slot_id, attr1.id) == 'charizard', 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr2.id) == 0, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr3.id) == 20, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr4.id) == 0, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr5.id) == 0, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr6.id) == 0, 'wrong value');
    assert(mock.slot_attribute_value(slot_id, attr7.id) == 50, 'wrong value');

    // test events
    assert_slot_attribute_update_event(mock_address, slot_id, attr2.id, attr2.attr_type, 1, 0);
    assert_slot_attribute_update_event(mock_address, slot_id, attr4.id, attr4.attr_type, 1148, 0);
    assert_slot_attribute_update_event(
        mock_address, slot_id, attr6.id, attr6.attr_type, 'timid', 0
    );
    assert_slot_attribute_update_event(mock_address, slot_id, attr5.id, attr5.attr_type, 'ash', 0);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid slot_id', 'ENTRYPOINT_FAILED'))]
fn test_remove_slot_attribute_invalid_slot_id() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.remove_attributes_from_slot(0, array![attr1.id].span());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: attr_id not in slot', 'ENTRYPOINT_FAILED'))]
fn test_remove_slot_attribute_attr_id_not_in_slot() {
    let mock_address = setup();
    let mock = IERC2114SlotAttrMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let slot_id = vars::TOKEN_ID();

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.remove_attributes_from_slot(slot_id, array![attr1.id].span());
}
// -------------------------------------------------------------------------- //
//                            Event Test Functions                            //
// -------------------------------------------------------------------------- //

fn assert_slot_attribute_update_event(
    contract_addr: ContractAddress,
    slot_id: u256,
    attr_id: u64,
    attr_type: AttrType,
    old_value: felt252,
    new_value: felt252
) {
    let event = pop_log::<ERC2114SlotAttr::Event>(contract_addr).unwrap();
    assert(
        event == ERC2114SlotAttr::Event::SlotAttributeUpdate(
            ERC2114SlotAttr::SlotAttributeUpdate {
                slot_id, attr_id, attr_type, old_value, new_value
            }
        ),
        'wrong SlotAttributeUpdate'
    );
}
// -------------------------------------------------------------------------- //
//                              Utils for testing                             //
// -------------------------------------------------------------------------- //

#[derive(Drop)]
struct Attr {
    id: u64,
    name: felt252,
    attr_type: AttrType,
}

#[inline(always)]
fn generate_attribute(id: u64, name: felt252, attr_type: AttrType) -> Attr {
    Attr { id, name, attr_type }
}
