use apibara_core::starknet::v1alpha2::FieldElement;
use starknet::core::types::Felt;

/// Converts a Felt element from starknet-rs to a FieldElement from Apibara-core.
pub fn felt_as_apibara_field(value: &Felt) -> FieldElement {
    FieldElement::from_bytes(&value.to_bytes_be())
}

/// Converts an Apibara core FieldElement into a Felt from starknet-rs.
pub fn apibara_field_as_felt(value: &FieldElement) -> Felt {
    Felt::from_bytes_be(&value.to_bytes())
}

pub trait FromFieldBytes: Sized {
    fn from_field_bytes(bytes: [u8; 32]) -> Self;
}

impl FromFieldBytes for u8 {
    fn from_field_bytes(bytes: [u8; 32]) -> Self {
        bytes[31]
    }
}

impl FromFieldBytes for u16 {
    fn from_field_bytes(bytes: [u8; 32]) -> Self {
        let last_two_bytes: [u8; 2] = bytes[30..32].try_into().expect("Slice with incorrect length");
        u16::from_be_bytes(last_two_bytes)
    }
}

impl FromFieldBytes for u32 {
    fn from_field_bytes(bytes: [u8; 32]) -> Self {
        let last_four_bytes: [u8; 4] = bytes[28..32].try_into().expect("Slice with incorrect length");
        u32::from_be_bytes(last_four_bytes)
    }
}

impl FromFieldBytes for u64 {
    fn from_field_bytes(bytes: [u8; 32]) -> Self {
        let last_eight_bytes: [u8; 8] = bytes[24..32].try_into().expect("Slice with incorrect length");
        u64::from_be_bytes(last_eight_bytes)
    }
}

impl FromFieldBytes for u128 {
    fn from_field_bytes(bytes: [u8; 32]) -> Self {
        let last_sixteen_bytes: [u8; 16] = bytes[16..32].try_into().expect("Slice with incorrect length");
        u128::from_be_bytes(last_sixteen_bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_u8_from_field_bytes() {
        let bytes = [0u8; 32];
        assert_eq!(u8::from_field_bytes(bytes), 0);

        let mut bytes = [0u8; 32];
        bytes[31] = 255;
        assert_eq!(u8::from_field_bytes(bytes), 255);

        let mut bytes = [0u8; 32];
        bytes[30] = 1;
        bytes[31] = 1;
        assert_eq!(u8::from_field_bytes(bytes), 1);
    }

    #[test]
    fn test_u32_from_field_bytes() {
        let bytes = [0u8; 32];
        assert_eq!(u32::from_field_bytes(bytes), 0);

        let mut bytes = [0u8; 32];
        bytes[28..32].copy_from_slice(&[1, 2, 3, 4]);
        assert_eq!(u32::from_field_bytes(bytes), 0x01020304);

        let mut bytes = [0u8; 32];
        bytes[31] = 255;
        assert_eq!(u32::from_field_bytes(bytes), 255);

        let mut bytes = [0u8; 32];
        bytes[28..32].fill(255);
        assert_eq!(u32::from_field_bytes(bytes), 0xFFFFFFFF);
    }

    #[test]
    fn test_u64_from_field_bytes() {
        let bytes = [0u8; 32];
        assert_eq!(u64::from_field_bytes(bytes), 0);

        let mut bytes = [0u8; 32];
        bytes[24..32].copy_from_slice(&[1, 2, 3, 4, 5, 6, 7, 8]);
        assert_eq!(u64::from_field_bytes(bytes), 0x0102030405060708);

        let mut bytes = [0u8; 32];
        bytes[31] = 255;
        assert_eq!(u64::from_field_bytes(bytes), 255);

        let mut bytes = [0u8; 32];
        bytes[24..32].fill(255);
        assert_eq!(u64::from_field_bytes(bytes), 0xFFFFFFFFFFFFFFFF);
    }

    #[test]
    fn test_u128_from_field_bytes() {
        let bytes = [0u8; 32];
        assert_eq!(u128::from_field_bytes(bytes), 0);

        let mut bytes = [0u8; 32];
        bytes[16..32].copy_from_slice(&(1..=16).collect::<Vec<u8>>());
        assert_eq!(u128::from_field_bytes(bytes), 0x0102030405060708090A0B0C0D0E0F10);

        let mut bytes = [0u8; 32];
        bytes[31] = 255;
        assert_eq!(u128::from_field_bytes(bytes), 255);

        let mut bytes = [0u8; 32];
        bytes[16..32].fill(255);
        assert_eq!(u128::from_field_bytes(bytes), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }
}
