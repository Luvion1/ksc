pub fn main() {
    let x = 10;
    let y = 20;
    
    // Test comparison operators
    if x < y {
        let result = x + y;
    } else {
        let result = x - y;
    }
    
    // Test logical operators
    if x > 5 && y < 30 {
        let combined = x * y;
    } else if x == 10 || y == 25 {
        let combined = x / y;
    }
    
    // Test nested conditions
    if x > 0 {
        if y > 0 {
            let positive = true;
        } else {
            let positive = false;
        }
    }
}