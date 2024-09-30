use cubit::f128::types::fixed::{
    ONE_u128, Fixed, FixedInto, FixedTrait, FixedAdd, FixedDiv, FixedMul, FixedNeg
};
use pragma_operations::{structures::{TickElem}, errors::OperationsErrors};

const ONE_YEAR_IN_SECONDS: u128 = 31536000_u128;

#[derive(Copy, Drop)]
enum Operations {
    SUBTRACTION: (),
    MULTIPLICATION: (),
}

/// Returns an array of `u128` from `TickElem` array
pub fn extract_value(mut tick_arr: Span<TickElem>) -> Array<Fixed> {
    let mut output = ArrayTrait::<Fixed>::new();
    loop {
        match tick_arr.pop_front() {
            Option::Some(cur_val) => { output.append(*cur_val.value); },
            Option::None(_) => { break (); }
        };
    };
    output
}

/// Sum the values of an array of `TickElem`
pub fn sum_tick_array(mut tick_arr: Span<TickElem>) -> u128 {
    let mut output = 0;
    loop {
        match tick_arr.pop_front() {
            Option::Some(cur_val) => { output += *cur_val.value.mag; },
            Option::None(_) => { break (); }
        };
    };

    output
}

/// Sum the elements of an array of `u128`
pub fn sum_array(mut tick_arr: Span<Fixed>) -> u128 {
    let mut output: u128 = 0;

    loop {
        match tick_arr.pop_front() {
            Option::Some(cur_val) => {
                if (*cur_val.sign == false) {
                    output = output + (*cur_val).mag;
                } else {
                    panic(array![OperationsErrors::SQUARE_OPERATION_FAILED])
                }
            },
            Option::None(_) => { break (); }
        };
    };
    output
}

/// Computes the mean of a `TickElem` array
pub fn mean(tick_arr: Span<TickElem>) -> u128 {
    let sum_ = sum_tick_array(tick_arr);
    sum_ / tick_arr.len().into()
}

/// Computes the variance of a `TickElem` array
pub fn variance(tick_arr: Span<TickElem>) -> u128 {
    let arr_ = extract_value(tick_arr);

    let arr_len = arr_.len();
    let mean_ = mean(tick_arr);
    let diff_arr = pairwise_1D_sub(arr_len, arr_.span(), FixedTrait::new(mag: mean_, sign: false));

    let diff_squared = pairwise_1D_mul(arr_len, diff_arr, diff_arr);

    let sum_ = sum_array(diff_squared);

    let variance_ = sum_ / arr_len.into();

    return variance_;
}

/// Computes the standard deviation of a `TickElem` array
/// Calls `variance` and computes the squared root
pub fn standard_deviation(arr: Span<TickElem>) -> u128 {
    let variance_ = variance(arr);
    let fixed_variance_ = FixedTrait::new(variance_ * ONE_u128, false);
    let std = FixedTrait::sqrt(fixed_variance_);
    std.mag / ONE_u128
}

/// Compute the volatility of a `TickElem` array
pub fn volatility(arr: Span<TickElem>) -> u128 {
    let _volatility_sum = _sum_volatility(arr);
    if (arr.len() == 0) {
        return 0;
    }
    let arr_len: u128 = arr.len().into() * ONE_u128;
    let fixed_len = FixedTrait::new(arr_len, false);
    let _volatility = _volatility_sum / fixed_len;
    let sqrt_vol = FixedTrait::sqrt(_volatility);
    return (sqrt_vol.mag * 100000000 / ONE_u128);
}

fn _sum_volatility(arr: Span<TickElem>) -> Fixed {
    let mut sum = FixedTrait::new(0, false);
    for i in 0
        ..arr
            .len() {
                let cur_val = *arr.at(i);
                let prev_val = *arr.at(i - 1);
                let cur_value = cur_val.value;
                let prev_value = prev_val.value;
                assert(prev_value.mag > 0, OperationsErrors::FAILED_TO_COMPUTE_VOLATILITY);
                let cur_timestamp = cur_val.tick;
                let prev_timestamp = prev_val.tick;
                assert(
                    cur_timestamp > prev_timestamp, OperationsErrors::FAILED_TO_COMPUTE_VOLATILITY
                );
                if (prev_timestamp > cur_timestamp) {
                    panic(array![OperationsErrors::FAILED_TO_COMPUTE_VOLATILITY]);
                }
                let numerator_value = FixedTrait::ln(cur_value / prev_value);
                let numerator = numerator_value.pow(FixedTrait::new(2 * ONE_u128, false));
                let denominator = FixedTrait::new((cur_timestamp - prev_timestamp).into(), false)
                    / FixedTrait::new(ONE_YEAR_IN_SECONDS, false);
                let fraction_ = numerator / denominator;
                sum = sum + fraction_;
            };
    sum
}

pub fn twap(arr: Span<TickElem>) -> u128 {
    let mut twap = 0;
    let mut sum_p = 0;
    let mut sum_t = 0;
    if (arr.len() == 0) {
        return 0;
    }

    if (arr.len() == 1) {
        return *arr.at(0).value.mag;
    }

    if (*arr.at(0).tick == *arr.at(arr.len() - 1).tick) {
        //we assume that all tick values are the same
        panic(array![OperationsErrors::FAILED_TO_COMPUTE_TWAP]);
    }
    for i in 0
        ..arr
            .len() {
                if *arr.at(i - 1).tick > *arr.at(i).tick {
                    //edge case
                    panic(array![OperationsErrors::FAILED_TO_COMPUTE_TWAP]);
                }
                let sub_timestamp = *arr.at(i).tick - *arr.at(i - 1).tick;

                let weighted_prices = *arr.at(i - 1).value.mag * sub_timestamp.into();
                sum_p = sum_p + weighted_prices;
                sum_t = sum_t + sub_timestamp;
            };
    twap = sum_p / sum_t.into();
    return twap;
}

/// Computes a result array given two arrays and one operation
/// e.g : [1, 2, 3] - 1 = [0,1, 2]
pub fn pairwise_1D_sub(x_len: u32, x: Span<Fixed>, y: Fixed) -> Span<Fixed> {
    //We assume, for simplicity, that the input arrays (x & y) are arrays of positive elements
    let mut output = ArrayTrait::<Fixed>::new();
    for i in 0
        ..x_len {
            let x1 = *x.get(i).unwrap().unbox();
            if x1 < y {
                output.append(FixedTrait::new(mag: y.mag - x1.mag, sign: true));
            } else {
                output.append(FixedTrait::new(mag: x1.mag - y.mag, sign: false));
            }
        };
    output.span()
}

/// Computes a result array given two arrays and one operation
/// e.g : [1, 2, 3] * [1, 2, 3] = [2, 4, 9]
pub fn pairwise_1D_mul(x_len: u32, x: Span<Fixed>, y: Span<Fixed>) -> Span<Fixed> {
    //We assume, for simplicity, that the input arrays (x & y) are arrays of positive
    let mut output = ArrayTrait::<Fixed>::new();
    for i in 0
        ..x_len {
            let x1 = *x.get(i).unwrap().unbox();
            let y1 = *y.get(i).unwrap().unbox();
            if x1.sign == y1.sign {
                output.append(FixedTrait::new(mag: x1.mag * y1.mag, sign: false));
            } else {
                output.append(FixedTrait::new(mag: x1.mag * y1.mag, sign: true));
            }
        };
    output.span()
}


/// Fills an array with one `value`
pub fn fill_1d(arr_len: u32, value: u128) -> Array<Fixed> {
    let mut output = ArrayTrait::new();
    for _ in 0..arr_len {
        output.append(FixedTrait::new(mag: value, sign: false));
    };
    output
}
