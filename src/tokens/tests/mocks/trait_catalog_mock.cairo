#[starknet::contract]
mod TraitCatalogMock {
    use seraphlabs::tokens::erc2114::extensions::trait_catalog::TraitCatalogComponent::TraitCatalogInitializerTrait;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::tokens::erc2114::extensions::TraitCatalogComponent;
    use seraphlabs::tokens::src5::SRC5Component;
    use starknet::ContractAddress;
    use TraitCatalogComponent::TraitCatalogInitializerImpl;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: TraitCatalogComponent, storage: trait_catalog, event: TraitCatalogEvent);

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl TraitCatalog = TraitCatalogComponent::TraitCatalogImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        trait_catalog: TraitCatalogComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event,
        TraitCatalogEvent: TraitCatalogComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.trait_catalog.initializer();
    }
}

#[starknet::contract]
mod InvalidTraitCatalogMock {
    use seraphlabs::tokens::erc2114::extensions::trait_catalog::TraitCatalogComponent::TraitCatalogInitializerTrait;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::tokens::erc2114::extensions::TraitCatalogComponent;
    use seraphlabs::tokens::src5::SRC5Component;
    use starknet::ContractAddress;
    use TraitCatalogComponent::TraitCatalogInitializerImpl;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: TraitCatalogComponent, storage: trait_catalog, event: TraitCatalogEvent);

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl TraitCatalog = TraitCatalogComponent::TraitCatalogImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        trait_catalog: TraitCatalogComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event,
        TraitCatalogEvent: TraitCatalogComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}
}
