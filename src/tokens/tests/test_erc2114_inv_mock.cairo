use seraphlabs::tokens::tests::mocks::erc2114_inv_mock::{
    ERC2114InvMock as Mock, IERC2114InvMockDispatcher, IERC2114InvMockDispatcherTrait,
};
use seraphlabs::tokens::erc2114::{extensions::ERC2114InvComponent, utils::AttrType};
use seraphlabs::tokens::tests::mocks::trait_catalog_mock::{
    TraitCatalogMock, InvalidTraitCatalogMock
};
use seraphlabs::tokens::erc2114::interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
use seraphlabs::tokens::constants;
use seraphlabs::utils::testing::{vars, helper};
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, pop_log, pop_log_raw};
use debug::PrintTrait;

const pill_slot: u256 = 1;
const ing_slot: u256 = 2;
const bg_slot: u256 = 3;

const name_attr: u64 = 1;
const ing_attr: u64 = 2;
const bg_attr: u64 = 3;
const mbill_attr: u64 = 4;

fn setup() -> ContractAddress {
    let trait_cat_calldata = array![];
    let trait_cat_addr = helper::deploy(TraitCatalogMock::TEST_CLASS_HASH, trait_cat_calldata);
    // generate_trait_list
    let trait_catalog = ITraitCatalogDispatcher { contract_address: trait_cat_addr };
    // generrate trait list for attr_id 1 `name` list_id 1
    trait_catalog.generate_trait_list(array!['pill', 'ingredient', 'background'].span());
    // generrate trait list for attr_id 3 `background` list_id 2
    trait_catalog.generate_trait_list(array!['yellow', 'pink', 'purple'].span());

    let mut calldata = array![];
    Serde::serialize(@trait_cat_addr, ref calldata);
    // set to true to create attributes
    Serde::serialize(@true, ref calldata);
    let mock_address = helper::deploy(Mock::TEST_CLASS_HASH, calldata);
    // drop 1 trait catalog attached event and 4 create attribute events
    helper::drop_events(mock_address, 5);
    mock_address
}

// set up that dosent include trait catalog list ids
fn simple_setup() -> ContractAddress {
    let trait_cat_calldata = array![];
    let trait_cat_addr = helper::deploy(TraitCatalogMock::TEST_CLASS_HASH, trait_cat_calldata);
    let mut calldata = array![];
    Serde::serialize(@trait_cat_addr, ref calldata);
    // set to false to not create attributes
    Serde::serialize(@false, ref calldata);
    let mock_address = helper::deploy(Mock::TEST_CLASS_HASH, calldata);
    // drop trait catalog attached event
    pop_log_raw(mock_address);
    mock_address
}

// -------------------------------------------------------------------------- //
//                                    Tests                                   //
// -------------------------------------------------------------------------- //

#[test]
#[available_gas(200000000)]
fn test_constructor() {
    let mock_address = simple_setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };

    assert(mock.supports_interface(constants::IERC721_ID), 'no erc721 interface');
    assert(mock.supports_interface(constants::IERC721_ENUMERABLE_ID), 'no erc721 enum interface');
    assert(mock.supports_interface(constants::IERC3525_ID), 'no erc3525 interface');
    assert(mock.supports_interface(constants::IERC2114_ID), 'no erc2114 interface');
    assert(mock.supports_interface(constants::IERC2114_INVENTORY_ID), 'no erc2114 inv interface');
}

#[test]
#[available_gas(200000000)]
fn test_set_slot_criteria() {
    let mock_address = simple_setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let capacity_1 = 20;
    let capacity_2 = 2114;
    let capacity_3 = 3525;

    // mock.mint_pill(owner, token_id, 0);
    // // drop 4 events 3 from 3525 mint and 1 from add attribute
    // helper::drop_events(mock_address, 4);
    // set slot criteria
    mock.set_slot_criteria(pill_slot, ing_slot, capacity_1);
    mock.set_slot_criteria(pill_slot, bg_slot, capacity_2);
    // check slot criteria capacity
    assert(mock.slot_criteria_capacity(pill_slot, ing_slot) == capacity_1, 'wrong capacity 1');
    assert(mock.slot_criteria_capacity(pill_slot, bg_slot) == capacity_2, 'wrong capacity 2');
    // increase capacity 
    mock.set_slot_criteria(pill_slot, ing_slot, capacity_3);
    assert(mock.slot_criteria_capacity(pill_slot, ing_slot) == capacity_3, 'wrong capacity 3');
    // test events
    assert_inventory_slot_criteria_event(mock_address, pill_slot, ing_slot, 0, capacity_1);
    assert_inventory_slot_criteria_event(mock_address, pill_slot, bg_slot, 0, capacity_2);
    assert_inventory_slot_criteria_event(mock_address, pill_slot, ing_slot, capacity_1, capacity_3);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: invalid slot capacity', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_criteria_zero_capacity() {
    let mock_address = simple_setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();

    mock.set_slot_criteria(pill_slot, ing_slot, 0);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: invalid slot capacity', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_criteria_same_capacity() {
    let mock_address = simple_setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let capacity = 20;

    mock.set_slot_criteria(pill_slot, ing_slot, capacity);
    mock.set_slot_criteria(pill_slot, ing_slot, capacity);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: invalid slot capacity', 'ENTRYPOINT_FAILED'))]
fn test_set_slot_criteria_decrease_capacity() {
    let mock_address = simple_setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let capacity = 20;

    mock.set_slot_criteria(pill_slot, ing_slot, capacity);
    mock.set_slot_criteria(pill_slot, ing_slot, capacity - 1);
}

#[test]
#[available_gas(200000000)]
fn test_set_inventory_attributes() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();

    let small_attr_ids = array![ing_attr, mbill_attr].span();
    let small_attr_ids_2 = array![mbill_attr, ing_attr].span();
    let big_attr_ids = array![name_attr, ing_attr, bg_attr, mbill_attr].span();
    let no_attr_ids: Span<u64> = array![].span();

    // set small attributes
    mock.set_inventory_attributes(pill_slot, small_attr_ids);
    // set big attributes
    mock.set_inventory_attributes(ing_slot, big_attr_ids);
    assert(mock.inventory_attributes_of(pill_slot) == small_attr_ids, 'wrong inv attr 1');
    assert(mock.inventory_attributes_of(ing_slot) == big_attr_ids, 'wrong inv attr 2');
    // turn small to big
    mock.set_inventory_attributes(pill_slot, big_attr_ids);
    // turn big to small
    mock.set_inventory_attributes(ing_slot, small_attr_ids);
    assert(mock.inventory_attributes_of(pill_slot) == big_attr_ids, 'wrong inv attr 3');
    assert(mock.inventory_attributes_of(ing_slot) == small_attr_ids, 'wrong inv attr 4');
    // clear attributes
    mock.set_inventory_attributes(pill_slot, no_attr_ids);
    // set small attributes 2
    mock.set_inventory_attributes(ing_slot, small_attr_ids_2);
    assert(mock.inventory_attributes_of(pill_slot) == no_attr_ids, 'wrong inv attr 5');
    assert(mock.inventory_attributes_of(ing_slot) == small_attr_ids_2, 'wrong inv attr 6');
    // test events
    assert_inventory_attributes_event(mock_address, pill_slot, small_attr_ids);
    assert_inventory_attributes_event(mock_address, ing_slot, big_attr_ids);
    assert_inventory_attributes_event(mock_address, pill_slot, big_attr_ids);
    assert_inventory_attributes_event(mock_address, ing_slot, small_attr_ids);
    assert_inventory_attributes_event(mock_address, pill_slot, no_attr_ids);
    assert_inventory_attributes_event(mock_address, ing_slot, small_attr_ids_2);
    helper::assert_no_events_left(mock_address);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: invalid attr_id', 'ENTRYPOINT_FAILED'))]
fn test_set_inventory_attributes_invalid_attr() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();

    let attr_ids = array![ing_attr, 0, mbill_attr].span();

    mock.set_inventory_attributes(pill_slot, attr_ids);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: duplicate attr_id', 'ENTRYPOINT_FAILED'))]
fn test_set_inventory_attributes_duplicate_attr() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();

    let attr_ids = array![ing_attr, bg_attr, mbill_attr, bg_attr].span();

    mock.set_inventory_attributes(pill_slot, attr_ids);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: attr_ids already set', 'ENTRYPOINT_FAILED'))]
fn test_set_inventory_attributes_same_sequence() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();

    let attr_ids = array![ing_attr, bg_attr, mbill_attr].span();

    mock.set_inventory_attributes(pill_slot, attr_ids);
    mock.set_inventory_attributes(pill_slot, attr_ids);
}
#[test]
#[available_gas(200000000)]
fn test_edit_inventory() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let pill_id = 1;
    let ing_id_1 = 2;
    let ing_id_2 = 3;
    let bg_id_1 = 4;
    let bg_id_2 = 5;
    let pill_id_2 = 6;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    // emit 4 events 3 from 3525 mint and 1 from add attribute
    mock.mint_pill(owner, pill_id, 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id_1, 'Cairo Cap', 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id_2, 'Pepe', 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_bg(owner, bg_id_1, 1, 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_bg(owner, bg_id_2, 2, 0);
    // emit 4 events 3 from 3525 mint and 1 from add attribute
    mock.mint_pill(owner, pill_id_2, 0);
    // ---------------------------- set slot criteria --------------------------- //
    // set pill_slot criteria -> ing_slot capacity 1, bg_slot capacity 2
    // set ing_slot criteria -> ing_slot capacity 1 
    // emits 3 events 1 for each set slot criteria
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    mock.set_slot_criteria(pill_slot, bg_slot, 2);
    mock.set_slot_criteria(ing_slot, ing_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    // scalar transfer ing to pill
    // emits 2 events 1 transfer and 1 scalar transfer 
    mock.scalar_transfer_from(owner, ing_id_1, pill_id);
    // emits 2 events 1 transfer and 1 scalar transfer 
    // scalar transfer pill_2 to pill
    mock.scalar_transfer_from(owner, pill_id_2, pill_id);
    // scalar transfer bg to pill
    // emits 4 events 2 transfer and 2 scalar transfer 
    mock.scalar_transfer_from(owner, bg_id_1, pill_id);
    mock.scalar_transfer_from(owner, bg_id_2, pill_id);
    // scalar transfer ing_2 to ing_1
    // emits 2 events 1 transfer and 1 scalar transfer 
    mock.scalar_transfer_from(owner, ing_id_2, ing_id_1);
    // drop events
    helper::drop_events(mock_address, 41);
    // check supply empty
    assert(mock.token_supply_in_inventory(pill_id, ing_slot) == 0, 'wrong supply 1');
    assert(mock.token_supply_in_inventory(pill_id, bg_slot) == 0, 'wrong supply 2');
    assert(mock.token_supply_in_inventory(ing_id_1, ing_slot) == 0, 'wrong supply 3');
    // check inventory empty
    assert(mock.inventory_of(pill_id) == array![].span(), 'wrong inventory 1');
    assert(mock.inventory_of(ing_id_1) == array![].span(), 'wrong inventory 2');
    // check equip status
    assert(mock.is_inside_inventory(pill_id, ing_id_1) == false, 'wrong equip status 1');
    assert(mock.is_inside_inventory(pill_id, pill_id_2) == false, 'wrong equip status 2');
    assert(mock.is_inside_inventory(pill_id, bg_id_1) == false, 'wrong equip status 3');
    assert(mock.is_inside_inventory(pill_id, bg_id_2) == false, 'wrong equip status 4');
    assert(mock.is_inside_inventory(ing_id_1, ing_id_2) == false, 'wrong equip status 5');
    // ------------------------------ equip tokens ------------------------------ //
    // equip ing_1 to pill ing_slot
    mock.edit_inventory(pill_id, ing_id_1, true);
    // equip bg_1 and bg_2 to pill bg_slot
    mock.edit_inventory(pill_id, bg_id_1, true);
    mock.edit_inventory(pill_id, bg_id_2, true);
    // equip ing_2 to ing_1 ing_slot
    mock.edit_inventory(ing_id_1, ing_id_2, true);
    assert(mock.token_supply_in_inventory(pill_id, ing_slot) == 1, 'wrong supply 4');
    assert(mock.token_supply_in_inventory(pill_id, bg_slot) == 2, 'wrong supply 5');
    assert(mock.token_supply_in_inventory(ing_id_1, ing_slot) == 1, 'wrong supply 6');
    // check inventory empty
    assert(
        mock.inventory_of(pill_id) == array![ing_id_1, bg_id_1, bg_id_2].span(), 'wrong inventory 3'
    );
    assert(mock.inventory_of(ing_id_1) == array![ing_id_2].span(), 'wrong inventory 4');
    // check equip status
    assert(mock.is_inside_inventory(pill_id, ing_id_1) == true, 'wrong equip status 6');
    assert(mock.is_inside_inventory(pill_id, pill_id_2) == false, 'wrong equip status 7');
    assert(mock.is_inside_inventory(pill_id, bg_id_1) == true, 'wrong equip status 8');
    assert(mock.is_inside_inventory(pill_id, bg_id_2) == true, 'wrong equip status 9');
    assert(mock.is_inside_inventory(ing_id_1, ing_id_2) == true, 'wrong equip status 10');
    // ----------------------------- unequip tokens ----------------------------- //
    // unequip bg_1 from pill bg_slot
    mock.edit_inventory(pill_id, bg_id_1, false);
    // unequip ing_2 from ing_1 ing_slot
    mock.edit_inventory(ing_id_1, ing_id_2, false);
    assert(mock.token_supply_in_inventory(pill_id, ing_slot) == 1, 'wrong supply 7');
    assert(mock.token_supply_in_inventory(pill_id, bg_slot) == 1, 'wrong supply 8');
    assert(mock.token_supply_in_inventory(ing_id_1, ing_slot) == 0, 'wrong supply 9');
    // check inventory empty
    assert(mock.inventory_of(pill_id) == array![ing_id_1, bg_id_2].span(), 'wrong inventory 5');
    assert(mock.inventory_of(ing_id_1) == array![].span(), 'wrong inventory 6');
    // check equip status
    assert(mock.is_inside_inventory(pill_id, ing_id_1) == true, 'wrong equip status 11');
    assert(mock.is_inside_inventory(pill_id, bg_id_1) == false, 'wrong equip status 12');
    assert(mock.is_inside_inventory(pill_id, bg_id_2) == true, 'wrong equip status 13');
    assert(mock.is_inside_inventory(ing_id_1, ing_id_2) == false, 'wrong equip status 14');
    // ------------------------------- test events ------------------------------ //
    assert_inventory_updated_event(mock_address, pill_id, ing_slot, ing_id_1, 0, 1);
    assert_inventory_updated_event(mock_address, pill_id, bg_slot, bg_id_1, 0, 1);
    assert_inventory_updated_event(mock_address, pill_id, bg_slot, bg_id_2, 1, 2);
    assert_inventory_updated_event(mock_address, ing_id_1, ing_slot, ing_id_2, 0, 1);
    assert_inventory_updated_event(mock_address, pill_id, bg_slot, bg_id_1, 2, 1);
    assert_inventory_updated_event(mock_address, ing_id_1, ing_slot, ing_id_2, 1, 0);
    helper::assert_no_events_left(mock_address);
}
#[test]
#[available_gas(200000000)]
fn test_edit_inventory_approved_operator() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let pill_id = 1;
    let ing_id = 2;
    let bg_id = 3;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    // emit 4 events 3 from 3525 mint and 1 from add attribute
    mock.mint_pill(owner, pill_id, 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id, 'Cairo Cap', 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_bg(owner, bg_id, 1, 0);
    // ---------------------------- set slot criteria --------------------------- //
    // set ing_slot criteria -> bg_slot capacity 1 
    // emits 1 event 1 for each set slot criteria
    mock.set_slot_criteria(ing_slot, bg_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    // scalar transfer ing to pill
    // emits 2 events 1 transfer and 1 scalar transfer 
    mock.scalar_transfer_from(owner, ing_id, pill_id);
    // emits 2 events 1 transfer and 1 scalar transfer 
    // scalar transfer bg to ing
    mock.scalar_transfer_from(owner, bg_id, ing_id);
    // ---------------------------- approve operator ---------------------------- //
    // emits 1 approve event
    mock.approve(operator, pill_id);
    // drop events
    helper::drop_events(mock_address, 20);
    // ------------------------------- equip token ------------------------------ //
    // set operator as caller address
    set_contract_address(operator);
    // equip bg to ing bg_slot
    mock.edit_inventory(ing_id, bg_id, true);
    assert(mock.token_supply_in_inventory(ing_id, bg_slot) == 1, 'wrong supply 1');
    // check inventory empty
    assert(mock.inventory_of(ing_id) == array![bg_id].span(), 'wrong inventory 1');
    // ------------------------------- test events ------------------------------ //
    assert_inventory_updated_event(mock_address, ing_id, bg_slot, bg_id, 0, 1);
    helper::assert_no_events_left(mock_address);
}
#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: caller is not approved', 'ENTRYPOINT_FAILED'))]
fn test_edit_inventory_unapproved_caller() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let pill_id = 1;
    let ing_id = 2;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    // emit 4 events 3 from 3525 mint and 1 from add attribute
    mock.mint_pill(owner, pill_id, 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id, 'Cairo Cap', 0);
    // ---------------------------- set slot criteria --------------------------- //
    // set ing_slot criteria -> bg_slot capacity 1 
    // emits 1 event 1 for each set slot criteria
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    // scalar transfer ing to pill
    // emits 2 events 1 transfer and 1 scalar transfer 
    mock.scalar_transfer_from(owner, ing_id, pill_id);
    // ------------------------------- equip token ------------------------------ //
    // set operator as caller address
    set_contract_address(operator);
    mock.edit_inventory(pill_id, ing_id, true);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: invalid token_id', 'ENTRYPOINT_FAILED'))]
fn test_edit_inventory_invalid_token_id() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let pill_id = 1;
    let ing_id = 2;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id, 'Cairo Cap', 0);
    // ---------------------------- set slot criteria --------------------------- //
    // set ing_slot criteria -> bg_slot capacity 1 
    // emits 1 event 1 for each set slot criteria
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    // ------------------------------- equip token ------------------------------ //
    // set operator as caller address
    set_contract_address(operator);
    mock.edit_inventory(pill_id, ing_id, true);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: invalid token parent', 'ENTRYPOINT_FAILED'))]
fn test_edit_inventory_not_direct_parent() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let pill_id = 1;
    let ing_id = 2;
    let bg_id = 3;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    mock.mint_pill(owner, pill_id, 0);
    mock.mint_ing(owner, ing_id, 'Cairo Cap', 0);
    mock.mint_bg(owner, bg_id, 1, 0);
    // ---------------------------- set slot criteria --------------------------- //
    mock.set_slot_criteria(pill_slot, bg_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    mock.scalar_transfer_from(owner, ing_id, pill_id);
    mock.scalar_transfer_from(owner, bg_id, ing_id);
    mock.edit_inventory(pill_id, bg_id, true);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: inventory up to date', 'ENTRYPOINT_FAILED'))]
fn test_edit_inventory_already_equipped() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let pill_id = 1;
    let ing_id = 2;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    mock.mint_pill(owner, pill_id, 0);
    mock.mint_ing(owner, ing_id, 'Cairo Cap', 0);
    // ---------------------------- set slot criteria --------------------------- //
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    mock.scalar_transfer_from(owner, ing_id, pill_id);
    mock.edit_inventory(pill_id, ing_id, true);
    mock.edit_inventory(pill_id, ing_id, true);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: inventory up to date', 'ENTRYPOINT_FAILED'))]
fn test_edit_inventory_already_unequipped() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let pill_id = 1;
    let ing_id = 2;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    mock.mint_pill(owner, pill_id, 0);
    mock.mint_ing(owner, ing_id, 'Cairo Cap', 0);
    // ---------------------------- set slot criteria --------------------------- //
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    mock.scalar_transfer_from(owner, ing_id, pill_id);
    mock.edit_inventory(pill_id, ing_id, false);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('ERC2114: inventory has no space', 'ENTRYPOINT_FAILED'))]
fn test_edit_inventory_exceed_capacity() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let pill_id = 1;
    let ing_id_1 = 2;
    let ing_id_2 = 3;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    mock.mint_pill(owner, pill_id, 0);
    mock.mint_ing(owner, ing_id_1, 'Cairo Cap', 0);
    mock.mint_ing(owner, ing_id_2, 'Cairo Cap', 0);
    // ---------------------------- set slot criteria --------------------------- //
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    mock.scalar_transfer_from(owner, ing_id_1, pill_id);
    mock.scalar_transfer_from(owner, ing_id_2, pill_id);
    mock.edit_inventory(pill_id, ing_id_1, true);
    mock.edit_inventory(pill_id, ing_id_2, true);
}

#[test]
#[available_gas(200000000)]
fn test_equipped_attribute_value() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let pill_id = 1;
    let ing_id_1 = 2;
    let ing_id_2 = 3;
    let ing_id_3 = 4;
    let bg_id_1 = 5;
    let bg_id_2 = 6;
    let bg_id_3 = 7;
    let pill_id_2 = 8;
    let ing_id_4 = 9;
    let bg_id_4 = 10;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    mock.mint_pill(owner, pill_id, 20);
    mock.mint_ing(owner, ing_id_1, 'WoJak', 33);
    mock.mint_ing(owner, ing_id_2, 'Cairo Cap', 20);
    mock.mint_ing(owner, ing_id_3, 'Pepe', 21);
    mock.mint_bg(owner, bg_id_1, 1, 20);
    mock.mint_bg(owner, bg_id_2, 2, 20);
    mock.mint_bg(owner, bg_id_3, 3, 20);
    mock.mint_pill(owner, pill_id_2, 0);
    mock.mint_ing(owner, ing_id_4, 'Bunny Plush', 20);
    mock.mint_bg(owner, bg_id_4, 3, 20);
    // ---------------------------- set slot criteria --------------------------- //
    // set pill_slot criteria -> ing_slot capacity 1, bg_slot capacity 3 
    // set bg_slot criteria -> ing_slot capacity 1 
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    mock.set_slot_criteria(pill_slot, bg_slot, 3);
    mock.set_slot_criteria(bg_slot, ing_slot, 1);
    mock.set_slot_criteria(bg_slot, pill_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    // traansfer bg first so it will be at the top of the enummeration list
    mock.scalar_transfer_from(owner, bg_id_1, pill_id);
    mock.scalar_transfer_from(owner, bg_id_2, pill_id);
    mock.scalar_transfer_from(owner, bg_id_3, pill_id);
    mock.scalar_transfer_from(owner, ing_id_1, pill_id);
    mock.scalar_transfer_from(owner, ing_id_2, pill_id);
    mock.scalar_transfer_from(owner, ing_id_3, bg_id_3);
    mock.scalar_transfer_from(owner, pill_id_2, bg_id_1);
    mock.scalar_transfer_from(owner, ing_id_4, pill_id_2);
    mock.scalar_transfer_from(owner, bg_id_4, pill_id_2);
    // ------------------------------ equip tokens ------------------------------ //
    mock.edit_inventory(pill_id, ing_id_2, true);
    mock.edit_inventory(pill_id, bg_id_1, true);
    mock.edit_inventory(pill_id, bg_id_2, true);
    mock.edit_inventory(pill_id, bg_id_3, true);
    mock.edit_inventory(bg_id_3, ing_id_3, true);
    // test values
    assert(mock.equipped_attribute_value(pill_id, name_attr) == 'pill', 'wrong value 1');
    assert(mock.equipped_attribute_value(pill_id, ing_attr) == 0, 'wrong value 2');
    assert(mock.equipped_attribute_value(pill_id, bg_attr) == 0, 'wrong value 3');
    assert(mock.equipped_attribute_value(pill_id, mbill_attr) == 20, 'wrong value 4');
    // ----------------------- set inventory attributes 1 ----------------------- //
    mock
        .set_inventory_attributes(
            pill_slot, array![name_attr, ing_attr, bg_attr, mbill_attr].span()
        );
    assert(mock.equipped_attribute_value(pill_id, name_attr) == 'pill', 'wrong value 5');
    assert(mock.equipped_attribute_value(pill_id, ing_attr) == 'Cairo Cap', 'wrong value 6');
    assert(mock.equipped_attribute_value(pill_id, bg_attr) == 'yellow', 'wrong value 7');
    assert(mock.equipped_attribute_value(pill_id, mbill_attr) == 100, 'wrong value 8');
    // ----------------------- set inventory attributes 2 ----------------------- //
    mock.set_inventory_attributes(bg_slot, array![ing_attr, mbill_attr].span());
    assert(mock.equipped_attribute_value(pill_id, name_attr) == 'pill', 'wrong value 9');
    // switch to pepe as now bg_id_3 is at the top of the enummeration list
    // and since it inheriits ing_attr it now has Pepe as a value to return to pill_id
    assert(mock.equipped_attribute_value(pill_id, ing_attr) == 'Pepe', 'wrong value 10');
    assert(mock.equipped_attribute_value(pill_id, bg_attr) == 'yellow', 'wrong value 11');
    assert(mock.equipped_attribute_value(pill_id, mbill_attr) == 121, 'wrong value 12');
    // ----------------------------- equip tokens 2 ----------------------------- //
    mock.edit_inventory(bg_id_1, pill_id_2, true);
    mock.edit_inventory(pill_id_2, ing_id_4, true);
    mock.edit_inventory(pill_id_2, bg_id_4, true);
    assert(mock.equipped_attribute_value(pill_id, name_attr) == 'pill', 'wrong value 13');
    // switch to Bunny Plush as now bg_id_1 is at the top of the enummeration list
    // and since it inheriits ing_attr it now has BunyPlush as a value to return to pill_id
    assert(mock.equipped_attribute_value(pill_id, ing_attr) == 'Bunny Plush', 'wrong value 14');
    assert(mock.equipped_attribute_value(pill_id, bg_attr) == 'yellow', 'wrong value 15');
    assert(mock.equipped_attribute_value(pill_id, mbill_attr) == 161, 'wrong value 16');
    assert(mock.equipped_attribute_value(pill_id_2, name_attr) == 'pill', 'wrong value 17');
    assert(mock.equipped_attribute_value(pill_id_2, ing_attr) == 'Bunny Plush', 'wrong value 18');
    assert(mock.equipped_attribute_value(pill_id_2, bg_attr) == 'purple', 'wrong value 19');
    assert(mock.equipped_attribute_value(pill_id_2, mbill_attr) == 40, 'wrong value 20');
}

#[test]
#[available_gas(200000000)]
fn test_erc2114_inv_scalar_transfer_and_remove() {
    let mock_address = setup();
    let mock = IERC2114InvMockDispatcher { contract_address: mock_address };
    let owner = vars::OWNER();
    let pill_id = 1;
    let ing_id_1 = 2;
    let ing_id_2 = 3;
    let bg_id_1 = 4;
    let bg_id_2 = 5;
    let pill_id_2 = 6;
    // set caller
    set_contract_address(owner);
    // ------------------------------- mint tokens ------------------------------ //
    // emit 4 events 3 from 3525 mint and 1 from add attribute
    mock.mint_pill(owner, pill_id, 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id_1, 'Cairo Cap', 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_ing(owner, ing_id_2, 'Pepe', 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_bg(owner, bg_id_1, 1, 0);
    // emit 5 events 3 from 3525 mint and 2 from add attribute
    mock.mint_bg(owner, bg_id_2, 2, 0);
    // emit 4 events 3 from 3525 mint and 1 from add attribute
    mock.mint_pill(owner, pill_id_2, 0);
    // ---------------------------- set slot criteria --------------------------- //
    // set pill_slot criteria -> ing_slot capacity 1, bg_slot capacity 2
    // set ing_slot criteria -> ing_slot capacity 1 
    // emits 3 events 1 for each set slot criteria
    mock.set_slot_criteria(pill_slot, ing_slot, 1);
    mock.set_slot_criteria(pill_slot, bg_slot, 2);
    mock.set_slot_criteria(ing_slot, ing_slot, 1);
    // ----------------------------- transfer tokens ---------------------------- //
    // drop events
    helper::drop_events(mock_address, 31);
    // scalar transfer ing to pill
    // emits 2 events 1 transfer and 1 scalar transfer 
    // emits 1 inventoryUpdated
    mock.scalar_transfer_from_2(owner, ing_id_1, pill_id);
    // emits 2 events 1 transfer and 1 scalar transfer 
    // scalar transfer pill_2 to pill
    mock.scalar_transfer_from_2(owner, pill_id_2, pill_id);
    // scalar transfer bg to pill
    // emits 2 events 1 transfer and 1 scalar transfer 
    // emits 1 inventoryUpdated
    mock.scalar_transfer_from_2(owner, bg_id_1, pill_id);
    // emits 2 events 1 transfer and 1 scalar transfer 
    // emits 1 inventoryUpdated
    mock.scalar_transfer_from_2(owner, bg_id_2, pill_id);
    // scalar transfer ing_2 to ing_1
    // emits 2 events 1 transfer and 1 scalar transfer 
    // emits 1 inventoryUpdated
    mock.scalar_transfer_from_2(owner, ing_id_2, ing_id_1);

    assert(mock.token_supply_in_inventory(pill_id, ing_slot) == 1, 'wrong supply 1');
    assert(mock.token_supply_in_inventory(pill_id, bg_slot) == 2, 'wrong supply 2');
    assert(mock.token_supply_in_inventory(ing_id_1, ing_slot) == 1, 'wrong supply 3');
    // check inventory empty
    assert(
        mock.inventory_of(pill_id) == array![ing_id_1, bg_id_1, bg_id_2].span(), 'wrong inventory 1'
    );
    assert(mock.inventory_of(ing_id_1) == array![ing_id_2].span(), 'wrong inventory 2');
    // check equip status
    assert(mock.is_inside_inventory(pill_id, ing_id_1) == true, 'wrong equip status 1');
    assert(mock.is_inside_inventory(pill_id, pill_id_2) == false, 'wrong equip status 2');
    assert(mock.is_inside_inventory(pill_id, bg_id_1) == true, 'wrong equip status 3');
    assert(mock.is_inside_inventory(pill_id, bg_id_2) == true, 'wrong equip status 4');
    assert(mock.is_inside_inventory(ing_id_1, ing_id_2) == true, 'wrong equip status 5');
    // ----------------------------- unequip tokens ----------------------------- //
    // unequip bg_1 from pill bg_slot
    // emits 1 inventoryUpdated
    // emits 2 events 1 transfer and 1 scalar remove
    mock.scalar_remove_from_2(pill_id, bg_id_1);
    // unequip ing_2 from ing_1 ing_slot
    // emits 1 inventoryUpdated
    // emits 2 events 1 transfer and 1 scalar remove
    mock.scalar_remove_from_2(ing_id_1, ing_id_2);
    // remove pill thats not equipepd
    // emits 2 events 1 transfer and 1 scalar remove
    mock.scalar_remove_from_2(pill_id, pill_id_2);
    assert(mock.token_supply_in_inventory(pill_id, ing_slot) == 1, 'wrong supply 4');
    assert(mock.token_supply_in_inventory(pill_id, bg_slot) == 1, 'wrong supply 5');
    assert(mock.token_supply_in_inventory(ing_id_1, ing_slot) == 0, 'wrong supply 6');
    // check inventory empty
    assert(mock.inventory_of(pill_id) == array![ing_id_1, bg_id_2].span(), 'wrong inventory 3');
    assert(mock.inventory_of(ing_id_1) == array![].span(), 'wrong inventory 4');
    // check equip status
    assert(mock.is_inside_inventory(pill_id, ing_id_1) == true, 'wrong equip status 6');
    assert(mock.is_inside_inventory(pill_id, bg_id_1) == false, 'wrong equip status 7');
    assert(mock.is_inside_inventory(pill_id, bg_id_2) == true, 'wrong equip status 8');
    assert(mock.is_inside_inventory(ing_id_1, ing_id_2) == false, 'wrong equip status 9');
    // ------------------------------- test events ------------------------------ //
    helper::drop_events(mock_address, 2);
    assert_inventory_updated_event(mock_address, pill_id, ing_slot, ing_id_1, 0, 1);
    helper::drop_events(mock_address, 4);
    assert_inventory_updated_event(mock_address, pill_id, bg_slot, bg_id_1, 0, 1);
    helper::drop_events(mock_address, 2);
    assert_inventory_updated_event(mock_address, pill_id, bg_slot, bg_id_2, 1, 2);
    helper::drop_events(mock_address, 2);
    assert_inventory_updated_event(mock_address, ing_id_1, ing_slot, ing_id_2, 0, 1);
    assert_inventory_updated_event(mock_address, pill_id, bg_slot, bg_id_1, 2, 1);
    helper::drop_events(mock_address, 2);
    assert_inventory_updated_event(mock_address, ing_id_1, ing_slot, ing_id_2, 1, 0);
    helper::drop_events(mock_address, 4);
    helper::assert_no_events_left(mock_address);
}

// -------------------------------------------------------------------------- //
//                                event testers                               //
// -------------------------------------------------------------------------- //

#[inline(always)]
fn assert_inventory_slot_criteria_event(
    contract_addr: ContractAddress,
    slot_id: u256,
    criteria: u256,
    old_capacity: u64,
    new_capacity: u64
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC2114InvEvent(
            ERC2114InvComponent::Event::InventorySlotCriteria(
                ERC2114InvComponent::InventorySlotCriteria {
                    slot_id, criteria, old_capacity, new_capacity
                }
            )
        ),
        'wrong InventorySlotCriteria'
    );
}

#[inline(always)]
fn assert_inventory_attributes_event(
    contract_addr: ContractAddress, slot_id: u256, attr_ids: Span<u64>,
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC2114InvEvent(
            ERC2114InvComponent::Event::InventoryAttributes(
                ERC2114InvComponent::InventoryAttributes { slot_id, attr_ids }
            )
        ),
        'wrong InventoryAttributes'
    );
}

#[inline(always)]
fn assert_inventory_updated_event(
    contract_addr: ContractAddress,
    token_id: u256,
    criteria: u256,
    child_id: u256,
    old_bal: u64,
    new_bal: u64
) {
    let event = pop_log::<Mock::Event>(contract_addr).unwrap();
    assert(
        event == Mock::Event::ERC2114InvEvent(
            ERC2114InvComponent::Event::InventoryUpdated(
                ERC2114InvComponent::InventoryUpdated {
                    token_id, criteria, child_id, old_bal, new_bal
                }
            )
        ),
        'wrong InventoryUpdated'
    );
}
