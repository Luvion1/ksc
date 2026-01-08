# K# Syntax Specification (v0.1)

Dokumen ini merinci aturan penulisan (sintaks) K#-lang berdasarkan prinsip *Aesthetic Simplicity* dan *Invisible Governance*.

## Daftar Isi
1. [Titik Awal (Entry Point)](#1-titik-awal-entry-point)
2. [Komentar (Comments)](#2-komentar-comments)
3. [Variabel & Konstanta](#3-variabel--konstanta)
4. [Tipe Data Bawaan (Built-in)](#4-tipe-data-bawaan-built-in)
5. [Konversi Tipe (Type Casting)](#5-konversi-tipe-type-casting)
6. [Logika & Perbandingan](#6-logika--perbandingan)
7. [Fungsi (Functions)](#7-fungsi-functions)
8. [Kontrol Alur (Control Flow)](#8-kontrol-alur-control-flow)
9. [Struktur Data & Ekstensi](#9-struktur-data--ekstensi)
10. [Enums & Generics](#10-enums--generics)
11. [Koleksi & Metode Standar](#11-koleksi--metode-standar)
12. [Nil Safety & Error Handling](#12-nil-safety--error-handling)
13. [Sistem Modul & Import (Rust Style)](#13-sistem-modul--import-rust-style)
14. [Visual Elegance](#14-visual-elegance)
15. [Penanganan Memori (SOIn)](#15-penanganan-memori-soin)

---

## 1. Titik Awal (Entry Point)
Setiap aplikasi K# wajib memiliki fungsi `main` dengan akses publik sebagai titik awal eksekusi program.
*   **Aturan:** Fungsi `main` tidak boleh memiliki parameter dan tidak mengembalikan nilai secara eksplisit.
```ksharp
pub fn main() {
    print("Selamat datang di K#")
}
```

## 2. Komentar (Comments)
*   `//` : Digunakan untuk penjelasan satu baris.
*   `/* ... */` : Digunakan untuk blok penjelasan.
*   **Detail:** Isi di dalam `/* */` wajib dimulai pada baris baru setelah simbol pembuka.
```ksharp
// Komentar singkat
/*
   Komentar ini menjelaskan logika yang
   kompleks dalam beberapa baris.
*/
```

## 3. Variabel & Konstanta
K# menggunakan `snake_case` untuk penamaan variabel dan `SCREAMING_SNAKE_CASE` untuk konstanta.

*   **Immutable (Default):** Nilai tidak dapat diubah setelah diinisialisasi.
    ```ksharp
    let name = "Kresna"
    ```
*   **Mutable:** Menggunakan `mut` agar nilai dapat diubah.
    ```ksharp
    let mut health = 100
    health = 95
    ```
*   **Constants:** Nilai harus diketahui saat kompilasi dan bersifat global/static.
    ```ksharp
    const MAX_POWER = 9000
    ```
*   **Shadowing:** Diperbolehkan mendeklarasikan variabel dengan nama yang sama di blok yang berbeda.

## 4. Tipe Data Bawaan (Built-in)
| Kategori | Tipe | Penjelasan |
| :--- | :--- | :--- |
| Integer | `i8`, `i16`, `i32`, `i64` | Bilangan bulat bertanda (signed) |
| Unsigned | `u8`, `u16`, `u32`, `u64` | Bilangan bulat tak bertanda (unsigned) |
| Float | `f32`, `f64` | Bilangan desimal |
| Text | `str` | String UTF-8 dinamis |
| Character | `char` | Satu karakter unicode (4 byte) |
| Logic | `bool` | Nilai `true` atau `false` |

## 5. Konversi Tipe (Type Casting)
K# melarang konversi implisit (otomatis) untuk menghindari bug presisi.
*   **Metode:** Gunakan `.to_[tipe]()`.
```ksharp
let rasio: f64 = 0.75
let persen = (rasio * 100.0).to_i32()
let teks_skor = persen.to_str()
```

## 6. Logika & Perbandingan
*   **Logika:** `&&` (AND), `||` (OR), `!` (NOT).
*   **Perbandingan:** `==` (Sama dengan), `!=` (Tidak sama dengan), `<`, `>`, `<=`, `>=`.
*   **Detail:** Perbandingan hanya bisa dilakukan antara tipe data yang identik.

## 7. Fungsi (Functions)
*   **Return:** Wajib menggunakan keyword `return`.
*   **Parameter:** Harus memiliki tipe data eksplisit jika tidak dapat diinferensi.
```ksharp
fn hitung_jarak(x1: i32, y1: i32, x2: i32, y2: i32) -> f64 {
    let dx = (x2 - x1).to_f64()
    let dy = (y2 - y1).to_f64()
    return (dx * dx + dy * dy).sqrt()
}
```

## 8. Kontrol Alur (Control Flow)
*   **If-Else:** Tidak memerlukan tanda kurung pada kondisi.
*   **Match:** Harus **exhaustive** (semua kemungkinan nilai harus ditangani). Gunakan `_` untuk menangkap sisa kasus.
    ```ksharp
    match skor {
        100 => print("Sempurna")
        80..99 => print("Bagus")
        _ => print("Coba lagi")
    }
    ```
*   **For Loop:** Iterasi koleksi secara aman.
    ```ksharp
    for user in database.users {
        print(user.name)
    }
    ```

## 9. Struktur Data & Ekstensi
*   **Struct:** Fokus pada data. Properti bersifat private secara default.
*   **Extension:** Tempat mendefinisikan metode. Memisahkan *State* dan *Logic*.
```ksharp
pub type Point struct {
    x: i32
    y: i32
}

ext Point {
    pub fn move_to(mut self, new_x: i32, new_y: i32) {
        self.x = new_x
        self.y = new_y
    }
}
```

## 10. Enums & Generics
*   **Enums:** Dapat menyimpan data (Algebraic Data Types).
    ```ksharp
    enum WebEvent {
        PageLoad,
        KeyPress(char),
        Click(x: i32, y: i32)
    }
    ```
*   **Generics:** Menggunakan `<T>` untuk fleksibilitas tipe tanpa duplikasi kode.

## 11. Koleksi & Metode Standar
*   **List:** Array dinamis yang ukurannya bisa berubah.
*   **Map:** Tabel hash untuk pasangan kunci-nilai.
*   **Aturan:** Koleksi mengikuti aturan *Ownership*. Jika dikirim ke fungsi tanpa `view`, koleksi akan dipindahkan (*Move*).

## 12. Nil Safety & Error Handling
K# tidak mengenal `null pointer exception`.
*   **Optional (`?`):** Tipe data yang mungkin bernilai `nil`.
*   **Error (`err`):** Menandakan fungsi yang bisa gagal.
```ksharp
fn cari_user(id: i32) -> User? err {
    let u = db.find(id) else {
        throw "User tidak ditemukan"
    }
    return u
}

// Penggunaan
let user = cari_user(1) or nil
```

## 13. Sistem Modul & Import (Rust Style)
*   `use` digunakan untuk membawa simbol ke dalam scope saat ini.
*   `::` digunakan untuk menelusuri path modul.

## 14. Visual Elegance
*   **String Interpolation:** Hanya mendukung variabel atau ekspresi sederhana di dalam `{}`.
*   **Named Arguments:** Memperjelas maksud parameter pada fungsi dengan banyak argumen.

## 15. Penanganan Memori (SOIn)
*   **View:** Compiler mengirimkan referensi (read-only) secara otomatis.
*   **Take:** Compiler memindahkan kepemilikan data. Data asal tidak bisa lagi diakses.
*   **Drop:** Compiler otomatis memanggil fungsi destruktor di akhir scope.
