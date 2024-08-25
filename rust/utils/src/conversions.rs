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
