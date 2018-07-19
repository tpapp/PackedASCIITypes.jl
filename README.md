# PackedASCIITypes

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![Build Status](https://travis-ci.org/tpapp/PackedASCIITypes.jl.svg?branch=master)](https://travis-ci.org/tpapp/PackedASCIITypes.jl)
[![Coverage Status](https://coveralls.io/repos/tpapp/PackedASCIITypes.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tpapp/PackedASCIITypes.jl?branch=master)
[![codecov.io](http://codecov.io/github/tpapp/PackedASCIITypes.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/PackedASCIITypes.jl?branch=master)

Julia package for representing short string-like objects in a fixed number of bytes.

## Overview

When working with large datasets that have short string, it is sometimes advantageous to encode these strings in a memory-efficient way.

A `<: PackedASCII` type packs short ASCII strings (of 7-bit characters) into blocks of 1, 2, 4, 8, or 16 bytes. Operations like `==`, `<`, `hash`, and conversions to and from `String` are defined, but a `<: PackedASCII` type is *neither a `<: AbstractString` nor an `<: AbstractVector`*, as accessing individual characters directly is suboptimal. Use these types for storage and comparison, and convert to a `String` for all other purposes.

## Status and installation

This is work in progress: I am experimenting with the interface, and will micro-optimize when that is finished. The package requires at least Julia `v"0.7-beta"`. You can install it directly as

```julia
pkg> https://github.com/tpapp/PackedASCIITypes.jl
```

## Usage

```julia
julia> using PackedASCIITypes

julia> pasc"AA"                        # shortest representation picked automatically
pasc2"AA"

julia> pasc"AA" > pasc"A"              # very fast < and ==
true

julia> pasc"AA" == pasc8"AA"           # select representation
true

julia> PackedASCII("AA") == pasc"AA"   # constructor, automatic representation
true

julia> String(pasc"abc")
"abc"
```

## Binary representations

The following representations are supported:

| type            | literal    | `sizeof()` | `maxlength()` |
|:----------------|:-----------|:-----------|:--------------|
| `PackedASCII1`  | `pasc1""`  | `1`        | `1`           |
| `PackedASCII2`  | `pasc2""`  | `2`        | `2`           |
| `PackedASCII4`  | `pasc4""`  | `4`        | `4`           |
| `PackedASCII8`  | `pasc8""`  | `8`        | `8`           |
| `PackedASCII17` | `pasc17""` | `16`       | `17`          |

They all follow the same layout: the some of the least significant bits contain the *length*, followed by the characters in reverse in 7-bit blocks, padded when they don't use the whole length, then (when necessary) some padding bits which are zero.

For example, this is how `"abc"` is encoded in 4 bytes in a `PackedASCII4`:

```
|     byte 3    |     byte 2    |     byte 1    |     byte 0    |
| |     'a'     |     'b'     |     'c'     | unused,zero | len |
|0|1 1 0 0 0 0 1|1 1 0 0 0 1 0|1 1 0 0 0 1 1|0 0 0 0 0 0 0|0 1 1|
 \
  \______ padding, always 0
```

This representation allows one to reinterpret the block of memory as an unsigned integer, and just use `<` for comparison.
