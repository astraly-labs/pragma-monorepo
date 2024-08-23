use serde::{Deserialize, Serialize};
use starknet_core::utils::cairo_short_string_to_felt;
use starknet_ff::FieldElement;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataFeed {
    pub assets: Vec<String>,
    pub contract_address: String,
    pub selector: String,
    pub calldata: Vec<FieldElement>,
}

impl DataFeed {
    pub fn new(assets: Vec<String>, contract_address: String, selector: String) -> Self {
        let calldata = assets.iter().map(|a| cairo_short_string_to_felt(a).unwrap()).collect();
        Self { assets, contract_address, selector, calldata }
    }
}

pub trait HasSelector {
    fn to_selector(&self) -> String;
}

pub enum AggregationMode {
    Median,
    Mean,
}

pub enum StateUpdate {
    Checkpoint,
}

impl HasSelector for AggregationMode {
    fn to_selector(&self) -> String {
        match self {
            AggregationMode::Median => "0x00".to_string(),
            AggregationMode::Mean => "0x01".to_string(),
        }
    }
}

impl HasSelector for StateUpdate {
    fn to_selector(&self) -> String {
        match self {
            StateUpdate::Checkpoint => "0x0270c07fa4205f06222fb499351ee48b50054a57b9599b4a462ea03b8e2b84d5".to_string(),
        }
    }
}
