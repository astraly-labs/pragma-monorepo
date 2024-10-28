use std::time::Duration;

use crate::configs::evm_config::EvmChainName;

pub const HYPERLANE_VERSION: u8 = 3;

pub const PING_INTERVAL_DURATION: Duration = Duration::from_secs(30);
pub const MAX_CLIENT_MESSAGE_SIZE: usize = 100 * 1024; // 100 KiB

// TODO: add support for this
/// The maximum number of bytes that can be sent per second per IP address.
/// If the limit is exceeded, the connection is closed.
pub const BYTES_LIMIT_PER_IP_PER_SECOND: u32 = 256 * 1024; // 256 KiB

pub const DEFAULT_ACTIVE_CHAIN: EvmChainName = EvmChainName::Mainnet;
