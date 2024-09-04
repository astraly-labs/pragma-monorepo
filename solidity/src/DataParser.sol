// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import "./libraries/BytesLib.sol";
import {BaseEntry, SpotMedianEntry, TWAPEntry, RealizedVolatilityEntry, OptionsEntry, PerpEntry, ParsedData} from "./interfaces/IDataParser.sol";

contract DataParserV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using BytesLib for bytes;
    TimelockControllerUpgradeable public timelock;

    uint16 constant SM = 21325;
    uint16 constant TW = 21591;
    uint16 constant RV = 21078;
    uint16 constant OP = 20304; 
    uint16 constant PP = 20560;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    function initialize(address admin, uint256 minDelay) public initializer  {
        __Ownable_init(admin);
        __UUPSUpgradeable_init();
        timelock = new TimelockControllerUpgradeable();
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = admin;
        executors[0] = admin;
        timelock.initialize(minDelay, proposers, executors, admin);

        // Transfer ownership to the timelock controller
        transferOwnership(address(timelock));
    }


    function parse(bytes calldata data) external pure returns (ParsedData memory) {
        uint16 dataType = data.toUint16(0);

        ParsedData memory parsedData;
        parsedData.dataType = dataType;
        if (dataType == SM) {
            parsedData.spotEntry = parseSpotData(data);
        } else if (dataType == TW) {
            parsedData.twapEntry = parseTWAPData(data);
        } else if (dataType == RV) {
            parsedData.rvEntry = parseRealizedVolatilityData(data);
        } else if (dataType == OP) {
            parsedData.optionsEntry = parseOptionsData(data);
        } else if (dataType == PP) {
            parsedData.perpEntry = parsePerpData(data);
        } else {
            revert("Unknown data type");
        }

        return parsedData;
    }

    function parsePairId(bytes memory data, uint256 index) internal pure returns (string memory, uint256) {
    uint8 pairIdLength = data.toUint8(index);
    index += 1;
    string memory pairId = string(data.slice(index, pairIdLength));
    index += pairIdLength;
    return (pairId, index);
}


    function parseBaseEntry(bytes memory data, uint256 startIndex) internal pure returns (BaseEntry memory, uint256) {
        BaseEntry memory baseEntry;
        uint256 index = startIndex;

        baseEntry.timestamp = data.toUint64(index);
        index += 8;

        baseEntry.source = string(data.toUint256(index));
        index += 32;

        baseEntry.publisher = string(data.toUint256(index));
        index += 32;

        return (baseEntry, index);
    }

    function parseSpotData(bytes memory data) internal pure returns (SpotMedianEntry memory) {
        SpotMedianEntry memory entry;
        uint256 index = 2; 

        (entry.base_entry, index) = parseBaseEntry(data, index);
        (entry.pair_id, index) = parsePairId(data, index);


        entry.price = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);

        return entry;
    }

    function parseTWAPData(bytes memory data) internal pure returns (TWAPEntry memory) {
        TWAPEntry memory entry;
        uint256 index = 2;

        (entry.base_entry, index) = parseBaseEntry(data, index);
        (entry.pair_id, index) = parsePairId(data, index);


        entry.twap_price = data.toUint256(index);
        index += 32;

        entry.time_period = data.toUint256(index);
        index += 32;

        entry.start_price = data.toUint256(index);
        index += 32;

        entry.end_price = data.toUint256(index);
        index += 32;

        entry.total_volume = data.toUint256(index);
        index += 32;

        entry.number_of_data_points = data.toUint256(index);

        return entry;
    }

    function parseRealizedVolatilityData(bytes memory data) internal pure returns (RealizedVolatilityEntry memory) {
        RealizedVolatilityEntry memory entry;
        uint256 index = 2;

        (entry.base_entry, index) = parseBaseEntry(data, index);
        (entry.pair_id, index) = parsePairId(data, index);


        entry.volatility = data.toUint256(index);
        index += 32;

        entry.time_period = data.toUint256(index);
        index += 32;

        entry.start_price = data.toUint256(index);
        index += 32;

        entry.end_price = data.toUint256(index);
        index += 32;

        entry.high_price = data.toUint256(index);
        index += 32;

        entry.low_price = data.toUint256(index);
        index += 32;

        entry.number_of_data_points = data.toUint256(index);

        return entry;
    }

    function parseOptionsData(bytes memory data) internal pure returns (OptionsEntry memory) {
        OptionsEntry memory entry;
        uint256 index = 2; 

        (entry.base_entry, index) = parseBaseEntry(data, index);
        (entry.pair_id, index) = parsePairId(data, index);


        entry.strike_price = data.toUint256(index);
        index += 32;

        entry.implied_volatility = data.toUint256(index);
        index += 32;

        entry.time_to_expiry = data.toUint256(index);
        index += 32;

        entry.is_call = data.toUint8(index) == 1;
        index += 1;

        entry.underlying_price = data.toUint256(index);
        index += 32;

        entry.option_price = data.toUint256(index);
        index += 32;

        entry.delta = data.toUint256(index);
        index += 32;

        entry.gamma = data.toUint256(index);
        index += 32;

        entry.vega = data.toUint256(index);
        index += 32;

        entry.theta = data.toUint256(index);
        index += 32;

        entry.rho = data.toUint256(index);

        return entry;
    }

    function parsePerpData(bytes memory data) internal pure returns (PerpEntry memory) {
        PerpEntry memory entry;
        uint256 index = 2; // Skip data type

        (entry.base_entry, index) = parseBaseEntry(data, index);
        (entry.pair_id, index) = parsePairId(data, index);


        entry.mark_price = data.toUint256(index);
        index += 32;

        entry.index_price = data.toUint256(index);
        index += 32;

        entry.funding_rate = data.toUint256(index);
        index += 32;

        entry.open_interest = data.toUint256(index);
        index += 32;

        entry.volume = data.toUint256(index);
        index += 32;

        entry.long_open_interest = data.toUint256(index);
        index += 32;

        entry.short_open_interest = data.toUint256(index);
        index += 32;

        entry.next_funding_time = data.toUint256(index);
        index += 32;

        entry.predicted_funding_rate = data.toUint256(index);
        index += 32;

        entry.max_leverage = data.toUint256(index);

        return entry;
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}