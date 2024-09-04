// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
    struct BaseEntry {
        uint64 timestamp; 
        string source; 
        string publisher;
    }

    struct SpotMedianEntry {
        BaseEntry base_entry;
        string pair_id;
        uint256 price;
        uint256 volume;
    }

struct TWAPEntry {
    BaseEntry base_entry;
    string pair_id;
    uint256 twap_price;
    uint256 time_period; 
    uint256 start_price;
    uint256 end_price;
    uint256 total_volume;
    uint256 number_of_data_points;
}

struct RealizedVolatilityEntry {
    BaseEntry base_entry;
    string pair_id;
    uint256 volatility; 
    uint256 time_period; 
    uint256 start_price;
    uint256 end_price;
    uint256 high_price;
    uint256 low_price;
    uint256 number_of_data_points;
}

struct OptionsEntry {
    BaseEntry base_entry;
    string pair_id;
    uint256 strike_price;
    uint256 implied_volatility; 
    uint256 time_to_expiry;
    bool is_call; 
    uint256 underlying_price;
    uint256 option_price;
    uint256 delta; 
    uint256 gamma; 
    uint256 vega;  
    uint256 theta; 
    uint256 rho;   
}

struct PerpEntry {
    BaseEntry base_entry;
    string pair_id;
    uint256 mark_price;
    uint256 index_price;
    uint256 funding_rate; 
    uint256 open_interest;
    uint256 volume;
    uint256 long_open_interest;
    uint256 short_open_interest;
    uint256 next_funding_time;
    uint256 predicted_funding_rate; 
    uint256 max_leverage; 
}

    struct ParsedData {
        uint16 dataType;
        SpotMedianEntry spotEntry;
        TWAPEntry twapEntry;
        RealizedVolatilityEntry rvEntry;
        OptionsEntry optionsEntry;
        PerpEntry perpEntry;
    }

/// @title IDataParser
/// @author Pragma Labs
/// @custom:contact security@pragma.build
interface IDataParser {
    /// @notice Initialize the data parser contract. Implements timelock and upgradeability features.
    /// @param admin Admin of the contract.
    /// @param minDelay Initial minimum delay in seconds for timelock operations.
    function initialize(address admin, uint256 minDelay) external;

    /// @notice Parses an encoded data feed.
    /// @dev message should be encoded following the specs (TODO: add docs)
    /// @dev ParsedData is a structure, where the first member (dataType) specifies what type of data is stored. Other elements will be set to 0.
    /// @param data The encoded data feed message.
    /// @return parsedData The parsed data feed message, filled in the specific structure.
    function parse(bytes calldata data) external pure returns (ParsedData memory);
}
