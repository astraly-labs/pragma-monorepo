use anyhow::{bail, Result};
use starknet::core::types::Felt;

pub trait FeltVecToString {
    fn to_string(&self) -> String;
}

impl FeltVecToString for Vec<Felt> {
    fn to_string(&self) -> String {
        self.iter()
            .flat_map(|felt| {
                let hex = felt.to_hex_string();
                (0..hex.len()).step_by(2).filter_map(move |i| {
                    if i + 2 <= hex.len() {
                        u8::from_str_radix(&hex[i..i + 2], 16).ok()
                    } else {
                        None
                    }
                })
            })
            .map(|byte| byte as char)
            .collect()
    }
}

pub fn felt_vec_to_vec_string(felts: &[Felt]) -> Result<Vec<String>> {
    let mut result = Vec::new();
    let mut i = 0;

    if felts.is_empty() {
        bail!("Empty input");
    }

    let sub_array_count = felts[i].to_bytes_be()[31] as usize;
    i += 1;

    for _ in 0..sub_array_count {
        if i >= felts.len() {
            bail!("Unexpected end of input");
        }

        let count = felts[i].to_bytes_be()[31] as usize;
        i += 1;

        if i + count > felts.len() {
            bail!("Invalid input length");
        }

        let slice = &felts[i..i + count];
        let storage_location = slice.to_vec().to_string(); // Using the FeltVecToString impl

        result.push(storage_location);

        i += count;
    }

    Ok(result)
}

pub fn process_nested_felt_array(felts: &[Felt]) -> Result<Vec<Vec<String>>> {
    let mut result = Vec::new();
    let mut i = 0;

    if felts.is_empty() {
        bail!("Empty input");
    }

    let outer_array_count = felts[i].to_bytes_be()[31] as usize;
    i += 1;

    for _ in 0..outer_array_count {
        if i >= felts.len() {
            bail!("Unexpected end of input");
        }

        let inner_array_count = felts[i].to_bytes_be()[31] as usize;
        i += 1;

        let mut inner_array = Vec::new();

        for _ in 0..inner_array_count {
            if i >= felts.len() {
                bail!("Unexpected end of input");
            }

            let count = felts[i].to_bytes_be()[31] as usize;
            i += 1;

            if i + count > felts.len() {
                bail!("Invalid input length");
            }

            let slice = &felts[i..i + count];
            let storage_location = slice.to_vec().to_string(); // Using the FeltVecToString impl

            inner_array.push(storage_location);

            i += count;
        }

        result.push(inner_array);
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;
    use starknet::macros::felt_dec;

    #[test]
    fn test_felt_vec_to_string() {
        let input: Vec<Felt> = vec![
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
        ];

        let result = input.to_string();

        assert_eq!(result, "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
    }

    #[test]
    fn test_felt_vec_to_vec_string() {
        let input: Vec<Felt> = vec![
            felt_dec!("2"), // Count of sub arrays
            felt_dec!("3"), // Count of elements in the first array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
            felt_dec!("3"), // Count of elements in the second array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
        ];

        let result = felt_vec_to_vec_string(&input).unwrap();

        assert_eq!(result.len(), 2);
        assert_eq!(result[0], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
        assert_eq!(result[1], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
    }

    #[test]
    fn test_process_nested_felt_array() {
        let mut input: Vec<Felt> = vec![
            felt_dec!("1"),
            felt_dec!("2"), // Count of sub arrays
            felt_dec!("3"), // Count of elements in the first array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
            felt_dec!("3"), // Count of elements in the second array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
        ];

        let result = process_nested_felt_array(&input).unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0][0], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
        assert_eq!(result[0][1], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");

        input = vec![
            felt_dec!("2"),
            felt_dec!("2"), // Count of sub arrays
            felt_dec!("3"), // Count of elements in the first array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
            felt_dec!("3"), // Count of elements in the second array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
            felt_dec!("2"), // Count of sub arrays
            felt_dec!("3"), // Count of elements in the first array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
            felt_dec!("3"), // Count of elements in the second array
            felt_dec!("180946006308525359965345158532346553211983108462325076142963585023296502126"),
            felt_dec!("90954189295124463684969781689350429239725285131197301894846683156275291225"),
            felt_dec!("276191619276790668637754154763775604"),
        ];

        let result = process_nested_felt_array(&input).unwrap();

        assert_eq!(result.len(), 2);
        assert_eq!(result[0][0], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
        assert_eq!(result[0][1], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
        assert_eq!(result[1][0], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
        assert_eq!(result[1][1], "file:///var/folders/kr/z3l_6qyn3znb6gbnddtvgsn40000gn/T/.tmpdY51LU/checkpoint");
    }
}
