use pragma_entry::entry::Entry;

use pragma_entry::structures::{SpotEntry, FutureEntry, BaseEntry, AggregationMode};

#[test]
fn test_aggregate_entries_median() {
    let mut entries = ArrayTrait::<SpotEntry>::new();
    let entry_1 = SpotEntry {
        base: BaseEntry { timestamp: 1000000, source: 1, publisher: 1001 },
        price: 10,
        pair_id: 1,
        volume: 10
    };
    let entry_2 = SpotEntry {
        base: BaseEntry { timestamp: 1000001, source: 1, publisher: 0234 },
        price: 20,
        pair_id: 1,
        volume: 30
    };
    let entry_3 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 30,
        pair_id: 1,
        volume: 30
    };
    let entry_4 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 40,
        pair_id: 1,
        volume: 30
    };
    let entry_5 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 50,
        pair_id: 1,
        volume: 30
    };
    //1 element
    entries.append(entry_1);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Median(())) == 10,
        'median aggregation failed(1)'
    );

    //2 elements
    entries.append(entry_2);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Median(())) == 15,
        'median aggregation failed(even)'
    );

    //3 elements
    entries.append(entry_3);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Median(())) == 20,
        'median aggregation failed(odd)'
    );

    //4 elements
    entries.append(entry_4);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Median(())) == 25,
        'median aggregation failed(even)'
    );

    //5 elements
    entries.append(entry_5);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Median(())) == 30,
        'median aggregation failed(odd)'
    );

    //FUTURES

    let mut f_entries = ArrayTrait::<FutureEntry>::new();
    let entry_1 = FutureEntry {
        base: BaseEntry { timestamp: 1000000, source: 1, publisher: 1001 },
        price: 10,
        pair_id: 1,
        volume: 10,
        expiration_timestamp: 1111111
    };
    let entry_2 = FutureEntry {
        base: BaseEntry { timestamp: 1000001, source: 1, publisher: 0234 },
        price: 20,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    let entry_3 = FutureEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 30,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    let entry_4 = FutureEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 40,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    let entry_5 = FutureEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 50,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    //1 element
    f_entries.append(entry_1);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Median(())) == 10,
        'median aggregation failed(1)'
    );
    //2 elements
    f_entries.append(entry_2);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Median(())) == 15,
        'median aggregation failed(even)'
    );

    //3 elements
    f_entries.append(entry_3);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Median(())) == 20,
        'median aggregation failed(odd)'
    );

    //4 elements
    f_entries.append(entry_4);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Median(())) == 25,
        'median aggregation failed(even)'
    );

    //5 elements
    f_entries.append(entry_5);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Median(())) == 30,
        'median aggregation failed(odd)'
    );
}


#[test]
fn test_aggregate_entries_mean() {
    let mut entries = ArrayTrait::<SpotEntry>::new();
    let entry_1 = SpotEntry {
        base: BaseEntry { timestamp: 1000000, source: 1, publisher: 1001 },
        price: 10,
        pair_id: 1,
        volume: 10
    };
    let entry_2 = SpotEntry {
        base: BaseEntry { timestamp: 1000001, source: 1, publisher: 0234 },
        price: 20,
        pair_id: 1,
        volume: 30
    };
    let entry_3 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 30,
        pair_id: 1,
        volume: 30
    };
    let entry_4 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 40,
        pair_id: 1,
        volume: 30
    };
    let entry_5 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 50,
        pair_id: 1,
        volume: 30
    };
    //1 element
    entries.append(entry_1);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Mean(())) == 10,
        'Mean aggregation failed(1)'
    );

    //2 elements
    entries.append(entry_2);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Mean(())) == 15,
        'Mean aggregation failed(even)'
    );

    //3 elements
    entries.append(entry_3);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Mean(())) == 20,
        'Mean aggregation failed(odd)'
    );

    //4 elements
    entries.append(entry_4);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Mean(())) == 25,
        'Mean aggregation failed(even)'
    );

    //5 elements
    entries.append(entry_5);
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Mean(())) == 30,
        'Mean aggregation failed(odd)'
    );
    //FUTURES

    let mut f_entries = ArrayTrait::<FutureEntry>::new();
    let entry_1 = FutureEntry {
        base: BaseEntry { timestamp: 1000000, source: 1, publisher: 1001 },
        price: 10,
        pair_id: 1,
        volume: 10,
        expiration_timestamp: 1111111
    };
    let entry_2 = FutureEntry {
        base: BaseEntry { timestamp: 1000001, source: 1, publisher: 0234 },
        price: 20,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    let entry_3 = FutureEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 30,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    let entry_4 = FutureEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 40,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    let entry_5 = FutureEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 50,
        pair_id: 1,
        volume: 30,
        expiration_timestamp: 1111111
    };
    //1 element
    f_entries.append(entry_1);

    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Mean(())) == 10,
        'median aggregation failed(1)'
    );
    //2 elements
    f_entries.append(entry_2);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Mean(())) == 15,
        'median aggregation failed(even)'
    );

    //3 elements
    f_entries.append(entry_3);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Mean(())) == 20,
        'median aggregation failed(odd)'
    );

    //4 elements
    f_entries.append(entry_4);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Mean(())) == 25,
        'median aggregation failed(even)'
    );

    //5 elements
    f_entries.append(entry_5);
    assert(
        Entry::aggregate_entries(f_entries.span(), AggregationMode::Mean(())) == 30,
        'median aggregation failed(odd)'
    );
}


#[test]
fn test_aggregate_timestamp_max() {
    let mut entries = ArrayTrait::<SpotEntry>::new();
    let entry_1 = SpotEntry {
        base: BaseEntry { timestamp: 1000000, source: 1, publisher: 1001 },
        price: 10,
        pair_id: 1,
        volume: 10
    };
    let entry_2 = SpotEntry {
        base: BaseEntry { timestamp: 1000001, source: 1, publisher: 0234 },
        price: 20,
        pair_id: 1,
        volume: 30
    };
    let entry_3 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 30,
        pair_id: 1,
        volume: 30
    };
    let entry_4 = SpotEntry {
        base: BaseEntry { timestamp: 1000002, source: 1, publisher: 1334 },
        price: 40,
        pair_id: 1,
        volume: 30
    };
    let entry_5 = SpotEntry {
        base: BaseEntry { timestamp: 1003002, source: 1, publisher: 1334 },
        price: 50,
        pair_id: 1,
        volume: 30
    };
    //1 element
    entries.append(entry_1);
    assert(
        Entry::aggregate_timestamps_max(entries.span()) == 1000000.try_into().unwrap(),
        'max timestp aggregation failed'
    );
    entries.append(entry_2);
    assert(
        Entry::aggregate_timestamps_max(entries.span()) == 1000001.try_into().unwrap(),
        'max timestp aggregation failed'
    );
    entries.append(entry_3);
    assert(
        Entry::aggregate_timestamps_max(entries.span()) == 1000002.try_into().unwrap(),
        'max timestp aggregation failed'
    );
    entries.append(entry_4);
    assert(
        Entry::aggregate_timestamps_max(entries.span()) == 1000002.try_into().unwrap(),
        'max timestp aggregation failed'
    );
    entries.append(entry_5);
    assert(
        Entry::aggregate_timestamps_max(entries.span()) == 1003002.try_into().unwrap(),
        'max timestp aggregation failed'
    );
}


#[test]
fn test_empty_array() {
    let mut entries = ArrayTrait::<SpotEntry>::new();
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Mean(())) == 0,
        'wrong agg for empty array'
    );
    assert(
        Entry::aggregate_entries(entries.span(), AggregationMode::Median(())) == 0,
        'wrong agg for empty array'
    );
    assert(Entry::aggregate_timestamps_max(entries.span()) == 0, 'wrong tmstp for empty array');
}
