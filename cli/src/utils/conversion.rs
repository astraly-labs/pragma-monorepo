use starknet_ff::FieldElement;

use crate::runtimes::support::madara::runtime_types::mp_felt::Felt252Wrapper;

pub fn string_to_felt_252_wrapper(s: &str) -> Felt252Wrapper {
    let fe = FieldElement::from_hex_be(s).unwrap();
    Felt252Wrapper(fe.to_bytes_be())
}

pub fn u128_to_felt_252_wrapper(n: u128) -> Felt252Wrapper {
    let u128_bytes = n.to_le_bytes();

    let mut u8_array: [u8; 32] = [0; 32];
    u8_array[..16].copy_from_slice(&u128_bytes);

    Felt252Wrapper(u8_array)
}
