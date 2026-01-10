# K# Compiler (ksc)

K# adalah bahasa pemrograman modern dengan fokus pada *Aesthetic Simplicity* dan *Invisible Governance*. Compiler ini ditulis dalam OCaml menggunakan Dune sebagai build system.

## Struktur Proyek

```
ksc/
├── src/                    # Kode sumber compiler
│   ├── lexer/             # Tokenisasi dan analisis leksikal
│   ├── parser/            # Parsing dan pembentukan AST
│   ├── ast/               # Definisi struktur AST
│   ├── semantic/          # Analisis semantik dan type checking
│   ├── codegen/           # Generasi kode
│   ├── compiler/          # Integrasi komponen compiler
│   └── ksharp.ml          # Modul utama compiler
├── examples/              # Contoh program K#
│   ├── basic/             # Contoh dasar
│   └── advanced/          # Contoh fitur canggih
├── tests/                 # Test suite
│   ├── unit/              # Unit test
│   ├── integration/       # Integration test
│   └── performance/       # Performance test
├── docs/                  # Dokumentasi
├── tools/                 # Alat bantu pengembangan
└── dune-project          # Konfigurasi Dune
```

## Fitur K# Language

- **Type Safety**: Sistem tipe yang kuat dengan type inference
- **Memory Safety**: Tanpa null pointer exception
- **Modern Syntax**: Sintaks yang bersih dan mudah dibaca
- **Pattern Matching**: Match expression yang powerful
- **Error Handling**: Sistem error handling yang elegan
- **Module System**: Sistem modul ala Rust

## Instalasi

1. Pastikan Anda memiliki OCaml dan Dune terinstal
2. Clone repository ini
3. Jalankan `dune build` untuk membangun compiler

## Penggunaan

```bash
# Build compiler
dune build

# Jalankan compiler pada file K#
./_build/default/src/ksharp.exe file.ks

# Jalankan test
dune runtest
```

## Kontribusi

Silakan lihat [CONTRIBUTING.md](docs/CONTRIBUTING.md) untuk panduan kontribusi.

## Lisensi

Proyek ini dilisensikan di bawah MIT License. Lihat [LICENSE](LICENSE) untuk detail lebih lanjut.