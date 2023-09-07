use seraphlabs::tokens::tests::mocks::erc2114_mock::{
    ERC2114Mock as Mock, IERC2114MockDispatcher, IERC2114MockDispatcherTrait,
};
use seraphlabs::tokens::erc2114::{ERC2114, utils::AttrType};
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


// deploy with invalid trait catalog 
fn invalid_setup() -> ContractAddress {
    let trait_cat_calldata = array![];
    let trait_cat_addr = helper::deploy(
        InvalidTraitCatalogMock::TEST_CLASS_HASH, trait_cat_calldata
    );

    let mut calldata = array![];
    Serde::serialize(@trait_cat_addr, ref calldata);
    helper::deploy(Mock::TEST_CLASS_HASH, calldata)
}

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

// set up that dosent include trait catalog list ids
fn simple_setup() -> ContractAddress {
    let trait_cat_calldata = array![];
    let trait_cat_addr = helper::deploy(TraitCatalogMock::TEST_CLASS_HASH, trait_cat_calldata);
    let mut calldata = array![];
    Serde::serialize(@trait_cat_addr, ref calldata);
    let mock_address = helper::deploy(Mock::TEST_CLASS_HASH, calldata);
    // drop trait catalog attached event
    pop_log_raw(mock_address);
    mock_address
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
    let mock = IERC2114MockDispatcher { contract_address: mock_address };

    assert(mock.supports_interface(constants::IERC721_ID), 'no erc721 interface');
    assert(mock.supports_interface(constants::IERC721_ENUMERABLE_ID), 'no erc721 enum interface');
    assert(mock.supports_interface(constants::IERC2114_ID), 'no erc2114 interface');
    assert(mock.get_trait_catalog() == trait_cat, 'wrong trait catalog');
    // test events
    assert_trait_catalog_attached_event(mock_address, vars::OWNER(), trait_cat);
}


#[test]
#[available_gas(200000000)]
fn test_scalar_transfer() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let token_id_1 = 1_u256;
    let token_id_2 = 2_u256;
    let token_id_3 = 3_u256;
    let token_id_4 = 4_u256;

    mock.mint(owner, token_id_1);
    mock.mint(owner, token_id_2);
    mock.mint(owner, token_id_3);
    mock.mint(owner, token_id_4);
    helper::drop_events(mock_address, 4);

    set_contract_address(owner);
    mock.scalar_transfer_from(owner, token_id_4, token_id_3);
    mock.scalar_transfer_from(owner, token_id_3, token_id_1);
    mock.scalar_transfer_from(owner, token_id_2, token_id_1);

    assert(mock.owner_of(token_id_1) == owner, 'wrong owner');
    assert(mock.owner_of(token_id_2) == mock_address, 'wrong owner');

    assert(mock.balance_of(owner) == 1_u256, 'wrong balance');
    assert(mock.balance_of(mock_address) == 3_u256, 'wrong balance');

    assert(mock.token_of_owner_by_index(owner, 0) == token_id_1, 'wrong token');
    assert(mock.token_of_owner_by_index(mock_address, 0) == token_id_4, 'wrong token');
    assert(mock.token_of_owner_by_index(mock_address, 1) == token_id_3, 'wrong token');
    assert(mock.token_of_owner_by_index(mock_address, 2) == token_id_2, 'wrong token');

    assert(mock.token_balance_of(1) == 2_u256, 'wrong token balance');
    assert(mock.token_balance_of(2) == 0_u256, 'wrong token balance');
    assert(mock.token_balance_of(3) == 1_u256, 'wrong token balance');

    assert(mock.token_of(token_id_1) == 0_u256, 'wrong parent');
    assert(mock.token_of(token_id_2) == token_id_1, 'wrong parent');
    assert(mock.token_of(token_id_3) == token_id_1, 'wrong parent');
    assert(mock.token_of(token_id_4) == token_id_3, 'wrong parent');

    assert(mock.token_of_token_by_index(token_id_1, 0) == token_id_3, 'wrong child');
    assert(mock.token_of_token_by_index(token_id_1, 1) == token_id_2, 'wrong child');

    // test events
    assert_scalar_transfer_event(mock_address, owner, token_id_4, token_id_3, true);
    assert_scalar_transfer_event(mock_address, owner, token_id_3, token_id_1, true);
    assert_scalar_transfer_event(mock_address, owner, token_id_2, token_id_1, true);
}


#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', 'ENTRYPOINT_FAILED'))]
fn test_scalar_transfer_invalid_token_id() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    set_contract_address(owner);
    mock.mint(owner, 1_u256);
    mock.scalar_transfer_from(owner, 2_u256, 1_u256);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid token_id', 'ENTRYPOINT_FAILED'))]
fn test_scalar_transfer_invalid_to_token_id() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    set_contract_address(owner);
    mock.mint(owner, 1_u256);
    mock.scalar_transfer_from(owner, 1_u256, 2_u256);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: token has parent', 'ENTRYPOINT_FAILED'))]
fn test_scalar_transfer_token_with_parent() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    set_contract_address(owner);
    mock.mint(owner, 1_u256);
    mock.mint(owner, 2_u256);
    mock.scalar_transfer_from(owner, 1_u256, 2_u256);
    mock.scalar_transfer_from(owner, 1_u256, 2_u256);
}
#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC721: invalid sender', 'ENTRYPOINT_FAILED'))]
fn test_scalar_transfer_invalid_from_address() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };

    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    set_contract_address(owner);

    mock.mint(owner, 1_u256);
    mock.mint(operator, 2_u256);

    mock.scalar_transfer_from(operator, 1_u256, 2_u256);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: cant transfer to self', 'ENTRYPOINT_FAILED'))]
fn test_scalar_transfer_to_self() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();

    set_contract_address(owner);
    mock.mint(owner, 1);
    mock.scalar_transfer_from(owner, 1, 1);
}

#[test]
#[available_gas(200000000)]
fn test_scalar_remove() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    mock.mint(owner, 1);
    mock.mint(owner, 2);
    mock.mint(owner, 3);
    mock.mint(owner, 4);
    mock.mint(owner, 5);

    mock.scalar_transfer_from(owner, 2, 1);
    mock.scalar_transfer_from(owner, 3, 1);
    mock.scalar_transfer_from(owner, 4, 1);
    mock.scalar_transfer_from(owner, 5, 4);
    helper::drop_events(mock_address, 13);

    mock.scalar_remove_from(1, 3);
    mock.scalar_remove_from(4, 5);

    assert(mock.balance_of(owner) == 3_u256, 'wrong balance');
    assert(mock.balance_of(mock_address) == 2_u256, 'wrong balance');

    assert(mock.owner_of(3) == owner, 'wrong owner');
    assert(mock.owner_of(5) == owner, 'wrong owner');

    assert(mock.token_of_owner_by_index(owner, 0) == 1, 'wrong token');
    assert(mock.token_of_owner_by_index(owner, 1) == 3, 'wrong token');
    assert(mock.token_of_owner_by_index(owner, 2) == 5, 'wrong token');
    assert(mock.token_of_owner_by_index(mock_address, 0) == 2, 'wrong token');
    assert(mock.token_of_owner_by_index(mock_address, 1) == 4, 'wrong token');

    assert(mock.token_balance_of(1) == 2, 'wrong token balance');
    assert(mock.token_balance_of(4) == 0, 'wrong token balance');

    assert(mock.token_of(3) == 0, 'wrong parent');
    assert(mock.token_of(5) == 0, 'wrong parent');

    assert(mock.token_of_token_by_index(1, 0) == 2, 'wrong child');
    assert(mock.token_of_token_by_index(1, 1) == 4, 'wrong child');
    // test events
    assert_scalar_remove_event(mock_address, 1, 3, owner, true);
    assert_scalar_remove_event(mock_address, 4, 5, owner, true);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid token parent', 'ENTRYPOINT_FAILED'))]
fn test_scalar_remove_invalid_parent() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    mock.mint(owner, 1);
    mock.mint(owner, 2);

    mock.scalar_remove_from(1, 2);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: caller is not approved', 'ENTRYPOINT_FAILED'))]
fn test_scalar_remove_unapproved_caller() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    set_contract_address(owner);

    mock.mint(operator, 1);
    mock.mint(owner, 2);
    mock.mint(owner, 3);

    mock.scalar_transfer_from(owner, 3, 2);
    mock.scalar_transfer_from(owner, 2, 1);
    mock.scalar_remove_from(2, 3);
}

#[test]
#[available_gas(20000000)]
fn test_create_attribute() {
    let mock_address = setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(2, 'type', AttrType::String(1));
    let attr3 = generate_attribute(3, 'rarity', AttrType::Number(4));

    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
    mock.create_attribute(attr3.id, attr3.attr_type, attr3.name);

    assert(mock.attribute_name(attr1.id) == attr1.name, 'wrong name');
    assert(mock.attribute_name(attr2.id) == attr2.name, 'wrong name');
    assert(mock.attribute_name(attr3.id) == attr3.name, 'wrong name');

    assert(mock.attribute_type(attr1.id) == attr1.attr_type, 'wrong type');
    assert(mock.attribute_type(attr2.id) == attr2.attr_type, 'wrong type');
    assert(mock.attribute_type(attr3.id) == attr3.attr_type, 'wrong type');
    // test events
    assert_attribute_created_event(mock_address, attr1.id, attr1.attr_type, attr1.name);
    assert_attribute_created_event(mock_address, attr2.id, attr2.attr_type, attr2.name);
    assert_attribute_created_event(mock_address, attr3.id, attr3.attr_type, attr3.name);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id', 'ENTRYPOINT_FAILED'))]
fn test_create_attribute_invalid_attr_id() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    let attr1 = generate_attribute(0, 'pokemon', AttrType::String(0));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: attr_id already exist', 'ENTRYPOINT_FAILED'))]
fn test_create_attribute_duplicate() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(1, 'rarity', AttrType::Number(4));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: Invalid attribute', 'ENTRYPOINT_FAILED'))]
fn test_create_attribute_invalid_name() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 0, AttrType::String(0));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: Invalid attribute', 'ENTRYPOINT_FAILED'))]
fn test_create_attribute_invalid_type() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::Empty);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid list_id', 'ENTRYPOINT_FAILED'))]
fn test_create_attribute_invalid_list_id() {
    let mock_address = setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(2));
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
}

#[test]
#[available_gas(20000000)]
fn test_add_attribute_to_token() {
    let mock_address = setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(1234, 'type', AttrType::String(1));
    let attr3 = generate_attribute(123, 'rarity', AttrType::Number(4));
    let attr4 = generate_attribute(12, 'level', AttrType::Number(0));

    // second set
    let attr5 = generate_attribute(12345, 'trainer', AttrType::String(0));
    let attr6 = generate_attribute(123456, 'nature', AttrType::String(0));

    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
    mock.create_attribute(attr3.id, attr3.attr_type, attr3.name);
    mock.create_attribute(attr4.id, attr4.attr_type, attr4.name);
    mock.create_attribute(attr5.id, attr5.attr_type, attr5.name);
    mock.create_attribute(attr6.id, attr6.attr_type, attr6.name);

    helper::drop_events(mock_address, 7);

    mock
        .add_attributes_to_token(
            token_id,
            array![attr1.id, attr2.id, attr3.id, attr4.id].span(),
            array!['charizard', 1, 20, 11].span()
        );

    assert(
        mock.attributes_of(token_id) == array![attr1.id, attr2.id, attr3.id, attr4.id].span(),
        'wrong attributes'
    );
    assert(mock.attribute_value(token_id, attr1.id) == 'charizard', 'wrong value');
    assert(mock.attribute_value(token_id, attr2.id) == 'fire', 'wrong value');
    assert(mock.attribute_value(token_id, attr3.id) == 20, 'wrong value');
    assert(mock.attribute_value(token_id, attr4.id) == 11, 'wrong value');

    mock
        .add_attributes_to_token(
            token_id,
            array![attr3.id, attr4.id, attr5.id, attr6.id].span(),
            array![0, 9, 'ash', 'timid'].span()
        );

    assert(
        mock
            .attributes_of(
                token_id
            ) == array![attr1.id, attr2.id, attr3.id, attr4.id, attr5.id, attr6.id]
            .span(),
        'wrong attributes'
    );
    assert(mock.attribute_value(token_id, attr1.id) == 'charizard', 'wrong value');
    assert(mock.attribute_value(token_id, attr2.id) == 'fire', 'wrong value');
    assert(mock.attribute_value(token_id, attr3.id) == 20, 'wrong value');
    assert(mock.attribute_value(token_id, attr4.id) == 20, 'wrong value');
    assert(mock.attribute_value(token_id, attr5.id) == 'ash', 'wrong value');
    assert(mock.attribute_value(token_id, attr6.id) == 'timid', 'wrong value');

    // test events
    assert_token_attribute_update_event(
        mock_address, token_id, attr1.id, attr1.attr_type, 0, 'charizard'
    );
    assert_token_attribute_update_event(mock_address, token_id, attr2.id, attr2.attr_type, 0, 1);
    assert_token_attribute_update_event(mock_address, token_id, attr3.id, attr3.attr_type, 0, 20);
    assert_token_attribute_update_event(mock_address, token_id, attr4.id, attr4.attr_type, 0, 11);
    assert_token_attribute_update_event(mock_address, token_id, attr4.id, attr4.attr_type, 11, 20);
    assert_token_attribute_update_event(
        mock_address, token_id, attr5.id, attr5.attr_type, 0, 'ash'
    );
    assert_token_attribute_update_event(
        mock_address, token_id, attr6.id, attr6.attr_type, 0, 'timid'
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid ids or values', 'ENTRYPOINT_FAILED'))]
fn test_add_attribute_to_token_with_unequal_args() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock
        .add_attributes_to_token(
            token_id, array![attr1.id].span(), array!['charizard', 'pikachu'].span()
        );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: attr_id already exist', 'ENTRYPOINT_FAILED'))]
fn test_add_attribute_no_string_duplicates() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array!['charizard'].span());
    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array!['pikachu'].span());
}


#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id value', 'ENTRYPOINT_FAILED'))]
fn test_add_attribute_invalid_value() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array![0].span());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id value', 'ENTRYPOINT_FAILED'))]
fn test_add_attribute_invalid_list_value() {
    let mock_address = setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'type', AttrType::String(1));
    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array![4].span());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id', 'ENTRYPOINT_FAILED'))]
fn test_add_attribute_invalid_attr_id() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    mock.mint(owner, token_id);
    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array!['charizard'].span());
}

#[test]
#[available_gas(20000000)]
fn test_remove_attribute() {
    let mock_address = setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));
    let attr2 = generate_attribute(1234, 'type', AttrType::String(1)); //remove
    let attr3 = generate_attribute(123, 'rarity', AttrType::Number(4)); // subtract
    // set 2
    let attr4 = generate_attribute(12, 'boost', AttrType::Number(8)); //remove
    let attr5 = generate_attribute(12345, 'trainer', AttrType::String(0)); //remove
    // set 3
    let attr6 = generate_attribute(123456, 'nature', AttrType::String(0));
    let attr7 = generate_attribute(1234567, 'level', AttrType::Number(0)); // subtract 0

    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);
    mock.create_attribute(attr2.id, attr2.attr_type, attr2.name);
    mock.create_attribute(attr3.id, attr3.attr_type, attr3.name);
    mock.create_attribute(attr4.id, attr4.attr_type, attr4.name);
    mock.create_attribute(attr5.id, attr5.attr_type, attr5.name);
    mock.create_attribute(attr6.id, attr6.attr_type, attr6.name);
    mock.create_attribute(attr7.id, attr7.attr_type, attr7.name);

    // add first set
    mock
        .add_attributes_to_token(
            token_id, array![attr1.id, attr2.id, attr3.id].span(), array!['charizard', 1, 20].span()
        );
    // add second set
    mock
        .add_attributes_to_token(
            token_id, array![attr4.id, attr5.id].span(), array![1148, 'ash'].span()
        );
    // add third set
    mock
        .add_attributes_to_token(
            token_id, array![attr6.id, attr7.id].span(), array!['timid', 50].span()
        );
    assert(
        mock
            .attributes_of(
                token_id
            ) == array![attr1.id, attr2.id, attr3.id, attr4.id, attr5.id, attr6.id, attr7.id]
            .span(),
        'wrong attributes'
    );
    // drop events
    helper::drop_events(mock_address, 15);
    // subtract events
    mock
        .remove_attributes_from_token(
            token_id,
            array![attr2.id, attr3.id, attr4.id, attr5.id, attr7.id].span(),
            array![0, 9, 1148, 0, 0].span()
        );

    assert(
        mock.attributes_of(token_id) == array![attr1.id, attr3.id, attr6.id, attr7.id].span(),
        'wrong attributes'
    );

    assert(mock.attribute_value(token_id, attr1.id) == 'charizard', 'wrong value');
    assert(mock.attribute_value(token_id, attr2.id) == 0, 'wrong value');
    assert(mock.attribute_value(token_id, attr3.id) == 11, 'wrong value');
    assert(mock.attribute_value(token_id, attr4.id) == 0, 'wrong value');
    assert(mock.attribute_value(token_id, attr5.id) == 0, 'wrong value');
    assert(mock.attribute_value(token_id, attr6.id) == 'timid', 'wrong value');
    assert(mock.attribute_value(token_id, attr7.id) == 50, 'wrong value');

    // test events
    assert_token_attribute_update_event(mock_address, token_id, attr2.id, attr2.attr_type, 1, 0);
    assert_token_attribute_update_event(mock_address, token_id, attr3.id, attr3.attr_type, 20, 11);
    assert_token_attribute_update_event(mock_address, token_id, attr4.id, attr4.attr_type, 1148, 0);
    assert_token_attribute_update_event(
        mock_address, token_id, attr5.id, attr5.attr_type, 'ash', 0
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid ids or values', 'ENTRYPOINT_FAILED'))]
fn test_remove_attribute_with_unequal_args() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));

    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    // add first set
    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array!['charizard'].span());

    mock.remove_attributes_from_token(token_id, array![attr1.id].span(), array![0, 0].span());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: attr_id not in token', 'ENTRYPOINT_FAILED'))]
fn test_remove_attribute_that_token_dont_own() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    // first set
    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));

    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.remove_attributes_from_token(token_id, array![attr1.id].span(), array![0].span());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id value', 'ENTRYPOINT_FAILED'))]
fn test_remove_attribute_subtract_string_type() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'pokemon', AttrType::String(0));

    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array!['charizard'].span());

    mock.remove_attributes_from_token(token_id, array![attr1.id].span(), array!['ditto'].span());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id value', 'ENTRYPOINT_FAILED'))]
fn test_remove_attribute_subtract_more_than_owned() {
    let mock_address = simple_setup();
    let mock = IERC2114MockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    set_contract_address(owner);

    let attr1 = generate_attribute(1, 'level', AttrType::Number(0));
    mock.mint(owner, token_id);
    mock.create_attribute(attr1.id, attr1.attr_type, attr1.name);

    mock.add_attributes_to_token(token_id, array![attr1.id].span(), array![20].span());

    mock.remove_attributes_from_token(token_id, array![attr1.id].span(), array![21].span());
}
// -------------------------------------------------------------------------- //
//                            Event Test Functions                            //
// -------------------------------------------------------------------------- //

fn assert_trait_catalog_attached_event(
    contract_addr: ContractAddress, from: ContractAddress, trait_catalog_addr: ContractAddress
) {
    let event = pop_log::<ERC2114::Event>(contract_addr).unwrap();
    assert(
        event == ERC2114::Event::TraitCatalogAttached(
            ERC2114::TraitCatalogAttached { from, trait_catalog_addr }
        ),
        'wrong TraitCatalogAttached'
    );
}

// scalar transfer always emits a Transfer event first and then a ScalarTransfer event
// set drop to true if you want to drop the Transfer event
fn assert_scalar_transfer_event(
    contract_addr: ContractAddress,
    from: ContractAddress,
    token_id: u256,
    to_token_id: u256,
    drop: bool
) {
    if drop {
        pop_log_raw(contract_addr);
    }

    let event = pop_log::<ERC2114::Event>(contract_addr).unwrap();
    assert(
        event == ERC2114::Event::ScalarTransfer(
            ERC2114::ScalarTransfer { from, token_id, to_token_id }
        ),
        'wrong ScalarTransfer'
    );
}

fn assert_scalar_remove_event(
    contract_addr: ContractAddress,
    from_token_id: u256,
    token_id: u256,
    to: ContractAddress,
    drop: bool
) {
    if drop {
        pop_log_raw(contract_addr);
    }

    let event = pop_log::<ERC2114::Event>(contract_addr).unwrap();
    assert(
        event == ERC2114::Event::ScalarRemove(
            ERC2114::ScalarRemove { from_token_id, token_id, to }
        ),
        'wrong ScalarRemove'
    );
}

fn assert_attribute_created_event(
    contract_addr: ContractAddress, attr_id: u64, attr_type: AttrType, name: felt252
) {
    let event = pop_log::<ERC2114::Event>(contract_addr).unwrap();
    assert(
        event == ERC2114::Event::AttributeCreated(
            ERC2114::AttributeCreated { attr_id, attr_type, name }
        ),
        'wrong AttributeCreated'
    );
}

fn assert_token_attribute_update_event(
    contract_addr: ContractAddress,
    token_id: u256,
    attr_id: u64,
    attr_type: AttrType,
    old_value: felt252,
    new_value: felt252
) {
    let event = pop_log::<ERC2114::Event>(contract_addr).unwrap();
    assert(
        event == ERC2114::Event::TokenAttributeUpdate(
            ERC2114::TokenAttributeUpdate { token_id, attr_id, attr_type, old_value, new_value }
        ),
        'wrong TokenAttributeUpdate'
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
