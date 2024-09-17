#[starknet::contract]
pub mod FeedTypeUniqueRouter {
    use alexandria_bytes::{Bytes, BytesTrait};
    use core::num::traits::Zero;
    use core::panic_with_felt252;
    use pragma_dispatcher::routers::feed_types::{
        errors, interface::{IFeedTypeRouter, IPragmaOracleWrapper, ISummaryStatsWrapper}
    };
    use pragma_dispatcher::types::pragma_oracle::SummaryStatsComputation;
    use pragma_feed_types::{Feed, FeedTrait, FeedType};
    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    use pragma_lib::types::{PragmaPricesResponse, OptionsFeedData, DataType, AggregationMode};
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        // Pragma Oracle contract
        pragma_oracle: IPragmaABIDispatcher,
        // Pragma Summary stats contract
        summary_stats: ISummaryStatsABIDispatcher,
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pragma_oracle_address: ContractAddress,
        summary_stats_address: ContractAddress
    ) {
        // [Check]
        assert(!pragma_oracle_address.is_zero(), errors::PRAGMA_ORACLE_IS_ZERO);
        assert(!summary_stats_address.is_zero(), errors::SUMMARY_STATS_IS_ZERO);

        // [Effect]
        let pragma_oracle = IPragmaABIDispatcher { contract_address: pragma_oracle_address };
        self.pragma_oracle.write(pragma_oracle);
        let summary_stats = ISummaryStatsABIDispatcher { contract_address: summary_stats_address };
        self.summary_stats.write(summary_stats);
    }
}
