pub fn main() {
    let x = 10;
    let y = 20;
    
    // Test comparison operators
    let is_less = x < y;
    if is_less {
        let result = x + y;
    }
    
    // Test logical operators with comparison results
    let cond1 = x > 5;
    let cond2 = y < 30;
    if cond1 && cond2 {
        let combined = x * y;
    }
}