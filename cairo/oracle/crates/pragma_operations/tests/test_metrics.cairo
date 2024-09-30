//Tests

use cubit::f128::types::fixed::{ONE_u128, FixedInto, FixedTrait, Fixed};
use pragma_operations::{
    structures::TickElem,
    metrics::{
        extract_value, pairwise_1D_sub, pairwise_1D_mul, standard_deviation, volatility, variance,
        mean, sum_tick_array, sum_array, fill_1d
    }
};
#[test]
fn test_utils() {
    //extract_value
    let mut array = ArrayTrait::<TickElem>::new();
    array.append(TickElem { tick: 1, value: FixedTrait::from_felt(1) });
    array.append(TickElem { tick: 2, value: FixedTrait::from_felt(2) });
    array.append(TickElem { tick: 3, value: FixedTrait::from_felt(3) });
    array.append(TickElem { tick: 4, value: FixedTrait::from_felt(4) });
    let new_arr = extract_value(array.span());
    assert(new_arr.len() == 4, 'wrong len');

    //sum_tick_array
    assert(*new_arr.at(0).mag == 1, 'wrong value');
    assert(*new_arr.at(1).mag == 2, 'wrong value');
    assert(*new_arr.at(2).mag == 3, 'wrong value');
    assert(*new_arr.at(3).mag == 4, 'wrong value');
    let sum_tick = sum_tick_array(array.span());
    assert(sum_tick == 10, 'wrong sum');

    //sum_array
    let mut fixed_arr = ArrayTrait::<Fixed>::new();
    fixed_arr.append(FixedTrait::new(mag: 1, sign: false));
    fixed_arr.append(FixedTrait::new(mag: 2, sign: false));
    fixed_arr.append(FixedTrait::new(mag: 3, sign: false));
    fixed_arr.append(FixedTrait::new(mag: 4, sign: false));
    assert(sum_array(fixed_arr.span()) == 10, 'wrong sum');

    //pairwise_1D
    let x = fill_1d(3, 1);
    let z = pairwise_1D_sub(3, x.span(), FixedTrait::new(mag: 2, sign: false));
    assert(*z.at(0).mag == 1, 'wrong value');
    assert(*z.at(0).sign == true, 'wrong value');
    assert(*z.at(1).mag == 1, 'wrong value');
    assert(*z.at(2).mag == 1, 'wrong value');

    //fill_1d
    let arr = fill_1d(3, 1);
    assert(arr.len() == 3, 'wrong len');
    assert(*arr.at(0).mag == 1, 'wrong value');
    assert(*arr.at(1).mag == 1, 'wrong value');
    assert(*arr.at(2).mag == 1, 'wrong value');

    //pairwise_1D
    let x = fill_1d(3, 3);
    let y = fill_1d(3, 2);
    let z = pairwise_1D_mul(3, x.span(), y.span());
    assert(*z.at(0).mag == 6, 'wrong value');
    assert(*z.at(0).sign == false, 'wrong value');
    assert(*z.at(1).mag == 6, 'wrong value');
    assert(*z.at(2).mag == 6, 'wrong value');
}

#[test]
fn test_metrics() {
    //mean
    let mut array = ArrayTrait::<TickElem>::new();
    array.append(TickElem { tick: 1, value: FixedTrait::from_felt(10) });
    array.append(TickElem { tick: 2, value: FixedTrait::from_felt(20) });
    array.append(TickElem { tick: 3, value: FixedTrait::from_felt(30) });
    array.append(TickElem { tick: 4, value: FixedTrait::from_felt(40) });
    assert(mean(array.span()) == 25, 'wrong mean');

    //variance
    let mut array = ArrayTrait::<TickElem>::new();
    array.append(TickElem { tick: 1, value: FixedTrait::from_felt(10) });
    array.append(TickElem { tick: 2, value: FixedTrait::from_felt(20) });
    array.append(TickElem { tick: 3, value: FixedTrait::from_felt(30) });
    array.append(TickElem { tick: 4, value: FixedTrait::from_felt(40) });
    array.append(TickElem { tick: 5, value: FixedTrait::from_felt(50) });
    assert(variance(array.span()) == 200, 'wrong variance');

    //standard deviation
    let mut array = ArrayTrait::<TickElem>::new();
    array.append(TickElem { tick: 1, value: FixedTrait::from_felt(10) });
    array.append(TickElem { tick: 2, value: FixedTrait::from_felt(20) });
    array.append(TickElem { tick: 3, value: FixedTrait::from_felt(30) });
    array.append(TickElem { tick: 4, value: FixedTrait::from_felt(40) });
    array.append(TickElem { tick: 5, value: FixedTrait::from_felt(50) });
    assert(standard_deviation(array.span()) == 14, 'wrong standard deviation');
    //volatility
    let mut array = ArrayTrait::<TickElem>::new();
    array.append(TickElem { tick: 1640995200, value: FixedTrait::from_felt(47686) });
    array.append(TickElem { tick: 1641081600, value: FixedTrait::from_felt(47345) });
    array.append(TickElem { tick: 1641168000, value: FixedTrait::from_felt(46458) });
    array.append(TickElem { tick: 1641254400, value: FixedTrait::from_felt(45897) });
    array.append(TickElem { tick: 1641340800, value: FixedTrait::from_felt(43569) });
    let value = volatility(array.span());
    assert(volatility(array.span()) == 48830960, 'wrong volatility'); //10^8
}
