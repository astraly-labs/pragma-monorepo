use alexandria_bytes::Bytes;

pub trait IntoBytes<T> {
    fn into_bytes(self: T) -> Bytes;
}
