pub mod Entry {
    use alexandria_sorting::MergeSort;
    use pragma_entry::errors;
    use pragma_entry::structures::{AggregationMode, HasPrice, HasBaseEntry,};
    //
    // Helpers
    //

    // @notice Aggregates entries for a specific value
    // @param entries_len: length of entries array
    // @param entries: pointer to first Entry in array
    // @return value: the aggregation value
    pub fn aggregate_entries<
        T,
        impl THasPrice: HasPrice<T>, // impl TPartialOrd: PartialOrd<T>,
        impl TCopy: Copy<T>,
        impl TDrop: Drop<T>,
        impl THasPartialOrd: PartialOrd<T>
    >(
        entries: Span<T>, aggregation_mode: AggregationMode
    ) -> u128 {
        if (entries.len() == 0) {
            return 0;
        }
        match aggregation_mode {
            AggregationMode::Median(()) => {
                let value: u128 = entries_median(entries);
                value
            },
            AggregationMode::Mean(()) => {
                let value: u128 = entries_mean(entries);
                value
            },
            AggregationMode::Error(()) => {
                panic(array![errors::WRONG_AGGREGATION_MODE]);
                0
            }
        }
    }


    // @notice returns the max timestamp of an entries array
    // @param entries: pointer to first Entry in array
    // @return last_updated_timestamp: the latest timestamp from the array
    pub fn aggregate_timestamps_max<
        T,
        impl THasBaseEntry: HasBaseEntry<T>, // impl TPartialOrd: PartialOrd<T>,
        impl TCopy: Copy<T>,
        impl TDrop: Drop<T>
    >(
        mut entries: Span<T>
    ) -> u64 {
        if (entries.len() == 0) {
            return 0;
        }
        let mut max_timestamp: u64 = (*entries[0_usize]).get_base_timestamp();
        let mut index = 1_usize;
        loop {
            match entries.pop_front() {
                Option::Some(entry) => {
                    if (*entry).get_base_timestamp() > max_timestamp {
                        max_timestamp = (*entry).get_base_timestamp();
                    }
                },
                Option::None(_) => { break max_timestamp; }
            };
        }
    }

    //

    // @notice returns the median value from an entries array
    // @param entries: array of entries to aggregate
    // @return value: the median value from the array of entries
    pub fn entries_median<
        T,
        impl TCopy: Copy<T>,
        impl TDrop: Drop<T>, // impl TPartialOrd: PartialOrd<T>,
        impl THasPrice: HasPrice<T>,
        impl THasPartialOrd: PartialOrd<T>
    >(
        entries: Span<T>
    ) -> u128 {
        let sorted_entries = MergeSort::sort(entries);
        let entries_len = sorted_entries.len();
        assert(entries_len > 0_usize, 'entries must not be empty');
        let is_even = 1 - entries_len % 2_usize;
        if (is_even == 0) {
            let median_idx = (entries_len) / 2;
            let median_entry = *sorted_entries.at(median_idx);
            median_entry.get_price()
        } else {
            let median_idx_1 = entries_len / 2;
            let median_idx_2 = median_idx_1 - 1;
            let median_entry_1 = (*sorted_entries.at(median_idx_1)).get_price();
            let median_entry_2 = (*sorted_entries.at(median_idx_2)).get_price();
            (median_entry_1 + median_entry_2) / (2)
        }
    }


    // @notice Returns the mean value from an entries array
    // @param entries: entries array to aggregate
    // @return value: the mean value from the array of entries
    fn entries_mean<T, impl THasPrice: HasPrice<T>, impl TCopy: Copy<T>, impl TDrop: Drop<T>>(
        mut entries: Span<T>
    ) -> u128 {
        let mut sum: u128 = 0;
        let mut index: u32 = 0;
        let entries_len: u32 = entries.len();
        loop {
            match entries.pop_front() {
                Option::Some(entry) => { sum += (*entry).get_price(); },
                Option::None(_) => { break sum / entries_len.into(); }
            };
        }
    }

    pub fn compute_median(entry_array: Array<u128>) -> u128 {
        let span_entry_array = entry_array.span();
        let sorted_array = MergeSort::sort(span_entry_array);
        let entries_len = sorted_array.len();
        assert(entries_len > 0_usize, 'entries must not be empty');
        let is_even = 1 - entries_len % 2_usize;
        if (is_even == 0) {
            let median_idx = (entries_len) / 2;
            let median_entry = *sorted_array.at(median_idx);
            median_entry
        } else {
            let median_idx_1 = entries_len / 2;
            let median_idx_2 = median_idx_1 - 1;
            let median_entry_1 = (*sorted_array.at(median_idx_1));
            let median_entry_2 = (*sorted_array.at(median_idx_2));
            (median_entry_1 + median_entry_2) / 2
        }
    }
}
