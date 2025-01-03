use std::time::Duration;

pub const HYPERLANE_VERSION: u8 = 3;

pub const PRAGMA_MAJOR_VERSION: u8 = 1;
pub const PRAGMA_MINOR_VERSION: u8 = 0;
pub const TRAILING_HEADER_SIZE: u8 = 0;

pub const PING_INTERVAL_DURATION: Duration = Duration::from_secs(30);
pub const MAX_CLIENT_MESSAGE_SIZE: usize = 100 * 1024; // 100 KiB
pub const FEED_UPDATED_CHANNEL_CAPACITY: usize = 1024;

// TODO: add support for this
/// The maximum number of bytes that can be sent per second per IP address.
/// If the limit is exceeded, the connection is closed.
pub const _BYTES_LIMIT_PER_IP_PER_SECOND: u32 = 256 * 1024; // 256 KiB
