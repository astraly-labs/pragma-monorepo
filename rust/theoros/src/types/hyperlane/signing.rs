use alloy::{hex, signers::Signature};
use serde::{
    ser::{SerializeStruct, Serializer},
    Deserialize, Serialize,
};
use std::fmt::{Debug, Formatter};

/// A signed type. Contains the original value and the signature.
#[derive(Clone, Eq, PartialEq, Deserialize)]
pub struct SignedType<T: Sized> {
    /// The value which was signed
    #[serde(alias = "checkpoint")]
    #[serde(alias = "announcement")]
    pub value: T,
    /// The signature for the value
    pub signature: Signature,
}

impl<T: Serialize> Serialize for SignedType<T> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut state = serializer.serialize_struct("SignedType", 3)?;
        state.serialize_field("value", &self.value)?;
        state.serialize_field("signature", &self.signature)?;
        let sig: [u8; 65] = self.signature.into();
        state.serialize_field("serialized_signature", &bytes_to_hex(&sig))?;
        state.end()
    }
}

impl<T: Debug> Debug for SignedType<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let sig = <[u8; 65]>::from(self.signature);
        write!(f, "SignedType {{ value: {:?}, signature: 0x{} }}", self.value, hex::encode(&sig[..]))
    }
}

/// Pretty print a byte slice, including a hex prefix
pub fn bytes_to_hex(bytes: &[u8]) -> String {
    format!("0x{}", hex::encode(bytes))
}
