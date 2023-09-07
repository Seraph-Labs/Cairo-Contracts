use starknet::ContractAddress;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::testing::pop_log_raw;

fn deploy(class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();
    address
}

// drop x ammount of events 
fn drop_events(address: ContractAddress, ammount: u16) {
    let mut x = ammount;
    loop {
        if x.is_zero() {
            break;
        }
        pop_log_raw(address);
        x -= 1;
    }
}
