pub fn pad_to_32_bytes(input: &[u8]) -> [u8; 32] {
    let mut result = [0u8; 32];
    result[32 - input.len()..].copy_from_slice(input);
    result
}
