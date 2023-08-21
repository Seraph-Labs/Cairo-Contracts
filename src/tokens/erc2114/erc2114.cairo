#[starknet::contract]
mod ERC2114 {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc2114::interface;
    use interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
    use seraphlabs::tokens::erc2114::utils::AttrType;
    use seraphlabs::tokens::erc2114::utils::{AttrBase, AttrBaseTrait};
    use seraphlabs::tokens::erc2114::utils::{AttrPack, AttrPackTrait};
    use seraphlabs::tokens::src5::{SRC5, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}};
    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };
    use starknet::storage_access::StorePacking;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        trait_catalog_contract: ContractAddress,
        attr_base: LegacyMap<u64, AttrBase>,
        token_attr_value: LegacyMap<(u256, u64), felt252>,
        token_balance: LegacyMap<u256, u256>,
        token_parent: LegacyMap<u256, u256>,
        index_to_token_child: LegacyMap<(u256, u256), u256>,
        index_to_token_attr_pack: LegacyMap<(u256, u64), felt252>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TraitCatalogAttached: TraitCatalogAttached,
        ScalarTransfer: ScalarTransfer,
        ScalarRemove: ScalarRemove,
        AttributeCreated: AttributeCreated,
        TokenAttributeUpdate: TokenAttributeUpdate
    }

    #[derive(Drop, starknet::Event)]
    struct TraitCatalogAttached {
        #[key]
        from: ContractAddress,
        #[key]
        trait_catalog_addr: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct ScalarTransfer {
        #[key]
        from: ContractAddress,
        #[key]
        token_id: u256,
        #[key]
        to_token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ScalarRemove {
        #[key]
        from_token_id: u256,
        #[key]
        token_id: u256,
        #[key]
        to: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct AttributeCreated {
        #[key]
        attr_id: u64,
        #[key]
        attr_type: AttrType,
        name: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct TokenAttributeUpdate {
        #[key]
        token_id: u256,
        #[key]
        attr_id: u64,
        #[key]
        attr_type: AttrType,
        #[key]
        old_value: felt252,
        #[key]
        new_value: felt252
    }
}
