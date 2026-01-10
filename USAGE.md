# Panduan Penggunaan K# (K-Sharp)

## Pengenalan

K# adalah bahasa pemrograman sistem modern yang menggabungkan performa setingkat C dengan produktivitas tinggi dan keamanan memori mutlak. K# dirancang untuk memberikan "Maximum Power, Minimal Noise" - kekuatan maksimal dengan kebisingan minimal.

## Instalasi dan Setup

### Prasyarat
- OCaml >= 4.14
- Dune >= 3.11
- Menhir >= 2.1

### Kompilasi Proyek
```bash
cd ksc
dune build
```

### Menjalankan Kompiler
```bash
# Kompilasi file K# menjadi kode mesin
./_build/default/bin/main.exe program.ks

# Contoh
./_build/default/bin/main.exe examples/hello.ks
```

## Sintaks Dasar K#

### Tipe Data Dasar
```ksharp
// Integer
let x: i32 = 42;
let y: i64 = 1000000000000;

// Unsigned Integer
let a: u8 = 255;
let b: u32 = 4294967295;

// Floating Point
let pi: f64 = 3.14159;
let e: f32 = 2.71828;

// Karakter dan String
let c: char = 'A';
let s: str = "Hello, K#!";

// Boolean
let is_valid: bool = true;
let is_error: bool = false;

// Unit (void)
let unit_val: unit = ();
```

### Variabel dan Konstanta
```ksharp
// Variabel mutable
let mut counter: i32 = 0;
counter = counter + 1;

// Variabel immutable (default)
let name: str = "K#";
// name = "Rust"; // Error: tidak bisa diubah

// Konstanta
const MAX_SIZE: i32 = 1000;
```

### Fungsi
```ksharp
// Fungsi dasar
fn add(a: i32, b: i32): i32 {
    return a + b;
}

// Fungsi publik
pub fn main() {
    let result: i32 = add(5, 3);
    println(result.to_string());
}

// Fungsi dengan tipe kembalian unit (opsional)
fn greet(name: str) {
    println("Hello, " + name + "!");
}
```

### Struktur Data

#### Struct
```ksharp
type Point {
    x: f64,
    y: f64
}

type Person {
    name: str,
    age: i32,
    email: str?
}

pub fn main() {
    let origin: Point = { x: 0.0, y: 0.0 };
    let person: Person = {
        name: "Alice",
        age: 30,
        email: "alice@example.com"
    };
    
    println("Point: (" + origin.x.to_string() + ", " + origin.y.to_string() + ")");
}
```

#### Enum
```ksharp
enum Result<T, E> {
    Ok(T),
    Err(E)
}

enum Color {
    Red,
    Green,
    Blue
}

pub fn main() {
    let success: Result<i32, str> = Ok(42);
    let error: Result<i32, str> = Err("Something went wrong");
    
    let color: Color = Red;
}
```

### Kontrol Alur

#### If-Else
```ksharp
fn check_number(n: i32) {
    if n > 0 {
        println("Positive");
    } else if n < 0 {
        println("Negative");
    } else {
        println("Zero");
    }
}
```

#### Match (Pattern Matching)
```ksharp
fn handle_result(res: Result<i32, str>) {
    match res {
        Ok(value) => println("Success: " + value.to_string()),
        Err(msg) => println("Error: " + msg)
    }
}

fn get_color_name(color: Color): str {
    match color {
        Red => "Red",
        Green => "Green",
        Blue => "Blue"
    }
}
```

#### Loop
```ksharp
// While loop
fn countdown(start: i32) {
    let mut n: i32 = start;
    while n > 0 {
        println(n.to_string());
        n = n - 1;
    }
    println("Blast off!");
}

// For loop
fn print_numbers() {
    let numbers: [i32] = [1, 2, 3, 4, 5];
    for num in numbers {
        println(num.to_string());
    }
}
```

### Tipe Data Koleksi

#### Array/List
```ksharp
let numbers: [i32] = [1, 2, 3, 4, 5];
let names: [str] = ["Alice", "Bob", "Charlie"];

// Array kosong
let empty: [f64] = [];

// Akses elemen
let first: i32 = numbers[0];
```

#### Map
```ksharp
let ages: Map<str, i32> = {
    "Alice": 25,
    "Bob": 30,
    "Charlie": 35
};

// Akses nilai
let alice_age: i32 = ages["Alice"];

// Iterasi
for (name, age) in ages {
    println(name + " is " + age.to_string() + " years old");
}
```

### Fitur Lanjutan

#### Optional Type
```ksharp
fn divide(a: f64, b: f64): f64? {
    if b == 0.0 {
        return nil;
    } else {
        return a / b;
    }
}

pub fn main() {
    let result: f64? = divide(10.0, 2.0);
    match result {
        Some(value) => println("Result: " + value.to_string()),
        None => println("Cannot divide by zero")
    }
}
```

#### Generic Function
```ksharp
fn swap<T>(a: T, b: T): (T, T) {
    return (b, a);
}

fn max<T>(a: T, b: T): T where T: Ord {
    if a > b {
        return a;
    } else {
        return b;
    }
}
```

## Contoh Program Lengkap

### Program Kalkulator Sederhana
```ksharp
// calculator.ks
enum Operation {
    Add,
    Subtract,
    Multiply,
    Divide
}

type Calculator {
    result: f64
}

impl Calculator {
    fn new(): Calculator {
        return { result: 0.0 };
    }
    
    fn calculate(&mut self, op: Operation, a: f64, b: f64): f64? {
        match op {
            Add => self.result = a + b,
            Subtract => self.result = a - b,
            Multiply => self.result = a * b,
            Divide => {
                if b == 0.0 {
                    return nil;
                }
                self.result = a / b;
            }
        }
        return Some(self.result);
    }
    
    fn get_result(&self): f64 {
        return self.result;
    }
}

pub fn main() {
    let mut calc: Calculator = Calculator::new();
    
    let result1: f64? = calc.calculate(Add, 10.0, 5.0);
    match result1 {
        Some(val) => println("10 + 5 = " + val.to_string()),
        None => println("Calculation failed")
    }
    
    let result2: f64? = calc.calculate(Divide, 10.0, 0.0);
    match result2 {
        Some(val) => println("10 / 0 = " + val.to_string()),
        None => println("Cannot divide by zero!")
    }
}
```

## Filosofi K# dalam Praktek

### 1. Invisible Governance (Manajemen Memori Tak Terlihat)
```ksharp
// Tidak perlu malloc/free atau GC
fn process_data() {
    let data: [i32] = [1, 2, 3, 4, 5];  // Alokasi otomatis
    let result: i32 = sum(data);       // Dealokasi otomatis
    return result;
}
```

### 2. Deterministic Speed (Kecepatan Pasti)
```ksharp
// Tanpa overhead GC, latensi rendah
fn real_time_processing() {
    while true {
        let sensor_data: f64 = read_sensor();
        let processed: f64 = filter_noise(sensor_data);
        send_to_actuator(processed);
        // Tidak ada jeda GC yang tak terduga
    }
}
```

### 3. Absolute Safety by Default (Keamanan Mutlak)
```ksharp
// Tidak ada null pointer exception
fn safe_access(data: [str]?) {
    match data {
        Some(arr) => {
            for item in arr {
                println(item);
            }
        }
        None => println("No data available")
    }
}
```

### 4. Aesthetic Simplicity (Kesederhanaan Estetik)
```ksharp
// Sintaks bersih dan mudah dibaca
type User {
    name: str,
    email: str,
    age: i32
}

fn create_user(name: str, email: str, age: i32): User {
    return { name, email, age };
}
```

### 5. Pass-by-Intent (Kirim Berdasarkan Niat)
```ksharp
// Kompiler menentukan cara pengiriman data yang paling efisien
fn process_large_data(data: [u8]) {  // Bisa copy, move, atau view
    // Proses data
}

fn main() {
    let large_array: [u8] = generate_large_data();
    process_large_data(large_array);  // Kompiler memilih cara terbaik
}
```

## Best Practices

### 1. Gunakan Tipe Data yang Tepat
```ksharp
// Hindari tipe data terlalu besar
let small_number: u8 = 255;  // Cukup untuk nilai 0-255

// Gunakan tipe signed untuk perhitungan matematis
let temperature: i32 = -10;
```

### 2. Manfaatkan Pattern Matching
```ksharp
// Hindari if-else bertingkat
match result {
    Ok(value) => handle_success(value),
    Err(error) => handle_error(error),
    Timeout => handle_timeout()
}
```

### 3. Gunakan Optional Type untuk Nilai yang Mungkin Null
```ksharp
// Hindari null pointer
fn find_user(id: i32): User? {
    // Cari user di database
    return user_or_nil;
}
```

### 4. Manfaatkan Type Safety
```ksharp
// Gunakan tipe khusus untuk domain tertentu
type Email {
    value: str
}

fn validate_email(email: Email): bool {
    // Validasi email
    return is_valid(email.value);
}
```

## Perbandingan dengan Bahasa Lain

| Fitur | C/C++ | Rust | Go | **K#** |
|-------|-------|------|----|--------|
| **Manajemen Memori** | Manual | Manual | GC | **Otomatis & Cepat** |
| **Keamanan** | Rendah | Tinggi | Tinggi | **Tinggi** |
| **Sintaks** | Kuno | Kompleks | Sederhana | **Modern & Bersih** |
| **Performa** | Maksimal | Maksimal | Menengah | **Maksimal** |

## Kesimpulan

K# adalah pilihan ideal untuk:
- **Sistem Embedded**: IoT, mikrokontroler
- **Game Engine**: Performa tinggi, latensi rendah
- **AI/ML**: Prosesing data intensif
- **Sistem Real-time**: Kontrol industri, robotika
- **Aplikasi Sistem**: OS, driver, toolchain

Dengan K#, Anda mendapatkan kekuatan bahasa sistem tanpa kompleksitas dan risiko yang biasanya menyertainya.