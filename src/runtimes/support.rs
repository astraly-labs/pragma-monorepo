pub type ChainPrefix = u16;
pub type ChainTokenSymbol = String;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SupportedRuntime {
    Madara,
}

impl From<ChainPrefix> for SupportedRuntime {
    fn from(v: ChainPrefix) -> Self {
        match v {
            0 => Self::Madara,
            _ => unimplemented!("Chain prefix not supported"),
        }
    }
}

impl From<ChainTokenSymbol> for SupportedRuntime {
    fn from(v: ChainTokenSymbol) -> Self {
        match v.as_str() {
            "ETH" => Self::Madara,
            _ => unimplemented!("Chain unit not supported"),
        }
    }
}

impl std::fmt::Display for SupportedRuntime {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Madara => write!(f, "Madara"),
        }
    }
}

#[subxt::subxt(runtime_metadata_path = "src/runtimes/artifacts/madara_metadata.scale")]
pub mod madara {}
