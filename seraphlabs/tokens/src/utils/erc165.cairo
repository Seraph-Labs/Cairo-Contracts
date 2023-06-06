// taken from Openzeppelin Introspection library (https://github.com/OpenZeppelin/cairo-contracts/blob/cairo-1/src/openzeppelin/introspection/erc165.cairo)
#[abi]
trait IERC165 {
    fn supports_interface(interface_id: u32) -> bool;
}

#[contract]
mod ERC165 {
    use super::IERC165;
    use seraphlabs_tokens::utils::constants::{IERC165_ID, INVALID_ID};

    struct Storage {
        supported_interfaces: LegacyMap<u32, bool>
    }

    impl ERC165 of IERC165 {
        fn supports_interface(interface_id: u32) -> bool {
            if interface_id == IERC165_ID {
                return true;
            }
            supported_interfaces::read(interface_id)
        }
    }

    #[view]
    fn supports_interface(interface_id: u32) -> bool {
        ERC165::supports_interface(interface_id)
    }

    #[internal]
    fn register_interface(interface_id: u32) {
        assert(interface_id != INVALID_ID, 'Invalid id');
        supported_interfaces::write(interface_id, true);
    }

    #[internal]
    fn deregister_interface(interface_id: u32) {
        assert(interface_id != IERC165_ID, 'Invalid id');
        supported_interfaces::write(interface_id, false);
    }
}
