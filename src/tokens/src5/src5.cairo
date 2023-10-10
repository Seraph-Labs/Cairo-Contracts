#[starknet::component]
mod SRC5Component {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::src5::interface;

    #[storage]
    struct Storage {
        supported_interfaces: LegacyMap<felt252, bool>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {}

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(SRC5Impl)]
    impl SRC5<
        TContractState, +HasComponent<TContractState>
    > of interface::ISRC5<ComponentState<TContractState>> {
        fn supports_interface(
            self: @ComponentState<TContractState>, interface_id: felt252
        ) -> bool {
            self._supports_interface(interface_id)
        }
    }

    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl SRC5InternalImpl<TContractState> of SRC5InternalTrait<TContractState> {
        #[inline(always)]
        fn _supports_interface(
            self: @ComponentState<TContractState>, interface_id: felt252
        ) -> bool {
            if interface_id == constants::ISRC5_ID {
                return true;
            }
            self.supported_interfaces.read(interface_id)
        }

        #[inline(always)]
        fn register_interface(ref self: ComponentState<TContractState>, interface_id: felt252) {
            self.supported_interfaces.write(interface_id, true);
        }

        #[inline(always)]
        fn deregister_interface(ref self: ComponentState<TContractState>, interface_id: felt252) {
            assert(interface_id != constants::ISRC5_ID, 'SRC5: Invalid interface id');
            self.supported_interfaces.write(interface_id, false);
        }
    }
}
