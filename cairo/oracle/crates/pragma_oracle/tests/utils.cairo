use pragma_oracle::utils::convert::{convert_via_usd, normalize_to_decimals};
#[test]
fn test_convert_via_usd() {
    let a_price: u128 = 100;
    let b_price: u128 = 100;
    let output_decimals: u32 = 6;
    let result: u128 = convert_via_usd(a_price, b_price, output_decimals);
    assert(result == 1000000, 'div failed'); //10**6 output decimals 

    let a_price: u128 = 250;
    let b_price: u128 = 12;
    let output_decimals: u32 = 6;
    let result: u128 = convert_via_usd(a_price, b_price, output_decimals);
    assert(result == 20833333, 'div failed'); //10**6 output decimals 

    let a_price: u128 = 25000000;
    let original_decimals: u32 = 6;
    let target_decimals: u32 = 8;
    let result: u128 = normalize_to_decimals(a_price, original_decimals, target_decimals);
    assert(result == 2500000000, 'div failed'); //10**8 output decimals

    let a_price: u128 = 25000000;
    let original_decimals: u32 = 8;
    let target_decimals: u32 = 6;
    let result: u128 = normalize_to_decimals(a_price, original_decimals, target_decimals);
    assert(result == 250000, 'div failed') //10**6 output decimals
}
