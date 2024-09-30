use cubit::f128::types::fixed::Fixed;

#[derive(Drop, Copy)]
pub struct TickElem {
    pub tick: u64,
    pub value: Fixed
}
