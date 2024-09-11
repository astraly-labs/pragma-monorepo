use core::traits::BitAnd;

pub impl FeltBitAnd of BitAnd<felt252> {
    fn bitand(lhs: felt252, rhs: felt252) -> felt252 {
        (Into::<felt252, u256>::into(lhs) & rhs.into()).try_into().unwrap()
    }
}

pub impl FeltDiv of Div<felt252> {
    fn div(lhs: felt252, rhs: felt252) -> felt252 {
        // Use u256 division as the felt_div is on the modular field
        let lhs256: u256 = lhs.into();
        let rhs256: u256 = rhs.into();
        (lhs256 / rhs256).try_into().unwrap()
    }
}
