use starknet::core::types::U256;

/// A type that can be signed. The signature will be of a hash of select
/// contents defined by `signing_hash`.
#[allow(unused)]
#[async_trait::async_trait]
pub trait Signable: Sized {
    /// A hash of the contents.
    /// The EIP-191 compliant version of this hash is signed by validators.
    fn signing_hash(&self) -> U256;
}

#[derive(Debug, Clone, PartialEq, Eq, Copy, Hash)]
/// An ECDSA signature
pub struct Signature {
    /// R value
    pub r: U256,
    /// S Value
    pub s: U256,
    /// V value
    pub v: u64,
}

/// A signed type. Contains the original value and the signature.
#[derive(Clone, Eq, PartialEq)]
pub struct SignedType<T: Signable> {
    /// The value which was signed
    pub value: T,
    /// The signature for the value
    pub signature: Signature,
}
