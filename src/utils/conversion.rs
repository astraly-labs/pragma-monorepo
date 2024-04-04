use hex::FromHex;

use crate::runtimes::support::madara::runtime_types::mp_felt::Felt252Wrapper;

pub fn string_to_felt_252_wrapper(s: &str) -> Felt252Wrapper {
    let prefix_removed = s.replace("0x", "");
    Felt252Wrapper(<[u8; 32]>::from_hex(prefix_removed).unwrap())
}

pub fn u128_to_felt_252_wrapper(n: u128) -> Felt252Wrapper {
    let u128_bytes = n.to_le_bytes();

    let mut u8_array: [u8; 32] = [0; 32];
    u8_array[..16].copy_from_slice(&u128_bytes);

    Felt252Wrapper(u8_array)
}
