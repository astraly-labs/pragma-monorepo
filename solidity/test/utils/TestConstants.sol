/// @title Constants
/// @author Pragma Labs
/// @custom:contact security@pragma.build
/// @notice Library exposing constants used for testing
library TestConstantsLib {
    /// @dev The hyperlane version
    uint8 internal constant HYPERLANE_VERSION = 3;
    /// @dev Major version
    uint8 internal constant MAJOR_VERSION = 1;
    ///  @dev Minor version
    uint8 internal constant MINOR_VERSION = 0;
    ///  @dev Minor version
    uint8 internal constant TRAILING_HEADER_SIZE = 0;
    /// @dev ETH/USD as uint256
    uint256 internal constant ETH_USD = uint256(0x4554482f555344);
    /// @dev BTC/USD as uint256
    uint256 internal constant BTC_USD = uint256(0x4254432f555344);

    /// @dev CRYPTO encoding (0 -> Crypto, see https://docs.pragma.build/ for reference)
    uint16 internal constant CRYPTO = uint16(0);
    /// @dev UNIQUE encoding (0 -> Unique,see https://docs.pragma.build/ for reference)
    uint8 internal constant UNIQUE = uint8(0);
    /// @dev SPOT encoding (0 -> Spot, see https://docs.pragma.build/ for reference)
    uint8 internal constant SPOT = uint8(0);
    /// @dev TWAP encoding (1 -> Twap, see https://docs.pragma.build/ for reference)
    uint8 internal constant TWAP = uint8(1);
    /// @dev REALIZED_VOLATILITY encoding (2 -> Realized volatility, see https://docs.pragma.build/ for reference)
    uint8 internal constant REALIZED_VOLATILITY = uint8(2);
    /// @dev OPTIONS encoding (3 -> Crypto, see https://docs.pragma.build/ for reference)
    uint8 internal constant OPTIONS = uint8(3);
    /// @dev PERP encoding (4 -> Crypto, see https://docs.pragma.build/ for reference)
    uint8 internal constant PERP = uint8(4);
}
