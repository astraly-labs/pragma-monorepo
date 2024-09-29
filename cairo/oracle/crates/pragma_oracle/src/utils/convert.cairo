use alexandria_math::pow;

const MAX_POWER: u128 = 10000000000000000000000000000000;

pub fn normalize_to_decimals(value: u128, original_decimals: u32, target_decimals: u32) -> u128 {
    if target_decimals >= original_decimals {
        value * pow(10, (target_decimals - original_decimals).into())
    } else {
        value / pow(10, (original_decimals - target_decimals).into())
    }
}
pub fn div_decimals(a_price: u128, b_price: u128, output_decimals: u128) -> u128 {
    let power: u128 = pow(10_u128, output_decimals);

    assert(power <= MAX_POWER, 'Conversion overflow');
    assert(a_price <= MAX_POWER, 'Conversion overflow');
    assert(b_price > 0, 'Division by zero');
    a_price * power / b_price
}

pub fn mul_decimals(a_price: u128, b_price: u128, output_decimals: u128) -> u128 {
    let power: u128 = pow(10_u128, output_decimals);

    assert(power <= MAX_POWER, 'Conversion overflow');
    assert(a_price <= MAX_POWER, 'Conversion overflow');

    a_price * b_price * power
}

pub fn convert_via_usd(a_price_in_usd: u128, b_price_in_usd: u128, output_decimals: u32) -> u128 {
    let power: u128 = pow(10_u128, output_decimals.into());

    assert(power <= MAX_POWER, 'Conversion overflow');
    assert(a_price_in_usd <= MAX_POWER, 'Conversion overflow');

    a_price_in_usd * power / b_price_in_usd
}

