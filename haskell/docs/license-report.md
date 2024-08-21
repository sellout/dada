**NB**: This captures the licenses associated with a particular set of dependency versions. If your own build solves differently, it’s possible that the licenses may have changed, or even that the set of dependencies itself is different. Please make sure you run [`cabal-plan license-report`](https://hackage.haskell.org/package/cabal-plan) on your own components rather than assuming this is authoritative.

# Dependency License Report

Bold-faced **`package-name`**s denote standard libraries bundled with `ghc-9.8.1`.

## Direct dependencies of `dada:lib:dada`

| Name | Version | [SPDX](https://spdx.org/licenses/) License Id | Description | Also depended upon by |
| --- | --- | --- | --- | --- |
| **`base`** | [`4.19.0.0`](http://hackage.haskell.org/package/base-4.19.0.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/base-4.19.0.0/src/LICENSE) | Basic libraries | *(core library)* |
| **`ghc`** | [`9.8.1`](http://hackage.haskell.org/package/ghc-9.8.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/ghc-9.8.1/src/LICENSE) | The GHC API |  |

## Indirect transitive dependencies

| Name | Version | [SPDX](https://spdx.org/licenses/) License Id | Description | Depended upon by |
| --- | --- | --- | --- | --- |
| **`array`** | [`0.5.6.0`](http://hackage.haskell.org/package/array-0.5.6.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/array-0.5.6.0/src/LICENSE) | Mutable and immutable arrays | `binary`, `containers`, `deepseq`, `ghc`, `ghci`, `stm` |
| **`binary`** | [`0.8.9.1`](http://hackage.haskell.org/package/binary-0.8.9.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/binary-0.8.9.1/src/LICENSE) | Binary serialisation for Haskell values using lazy ByteStrings | `ghc`, `ghc-boot`, `ghci` |
| **`bytestring`** | [`0.12.0.2`](http://hackage.haskell.org/package/bytestring-0.12.0.2) | [`BSD-3-Clause`](http://hackage.haskell.org/package/bytestring-0.12.0.2/src/LICENSE) | Fast, compact, strict and lazy byte strings with a list interface | `binary`, `filepath`, `ghc`, `ghc-boot`, `ghci`, `unix` |
| **`containers`** | [`0.6.8`](http://hackage.haskell.org/package/containers-0.6.8) | [`BSD-3-Clause`](http://hackage.haskell.org/package/containers-0.6.8/src/LICENSE) | Assorted concrete container types | `binary`, `ghc`, `ghc-boot`, `ghc-heap`, `ghci`, `hpc` |
| **`deepseq`** | [`1.5.0.0`](http://hackage.haskell.org/package/deepseq-1.5.0.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/deepseq-1.5.0.0/src/LICENSE) | Deep evaluation of data structures | `bytestring`, `containers`, `filepath`, `ghc`, `ghc-boot`, `ghci`, `hpc`, `pretty`, `process`, `time` |
| **`directory`** | [`1.3.8.1`](http://hackage.haskell.org/package/directory-1.3.8.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/directory-1.3.8.1/src/LICENSE) | Platform-agnostic library for filesystem operations | `ghc`, `ghc-boot`, `hpc`, `process` |
| **`exceptions`** | [`0.10.7`](http://hackage.haskell.org/package/exceptions-0.10.7) | [`BSD-3-Clause`](http://hackage.haskell.org/package/exceptions-0.10.7/src/LICENSE) | Extensible optionally-pure exceptions | `filepath`, `ghc`, `semaphore-compat` |
| **`filepath`** | [`1.4.100.4`](http://hackage.haskell.org/package/filepath-1.4.100.4) | [`BSD-3-Clause`](http://hackage.haskell.org/package/filepath-1.4.100.4/src/LICENSE) | Library for manipulating FilePaths in a cross platform way. | `directory`, `ghc`, `ghc-boot`, `ghci`, `hpc`, `process`, `unix` |
| **`ghc-bignum`** | [`1.3`](http://hackage.haskell.org/package/ghc-bignum-1.3) | [`BSD-3-Clause`](http://hackage.haskell.org/package/ghc-bignum-1.3/src/LICENSE) | GHC BigNum library | `base` |
| **`ghc-boot`** | [`9.8.1`](http://hackage.haskell.org/package/ghc-boot-9.8.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/ghc-boot-9.8.1/src/LICENSE) | Shared functionality between GHC and its boot libraries | `ghc`, `ghci` |
| **`ghc-boot-th`** | [`9.8.1`](http://hackage.haskell.org/package/ghc-boot-th-9.8.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/ghc-boot-th-9.8.1/src/LICENSE) | Shared functionality between GHC and the @template-haskell@ library | `ghc-boot`, `template-haskell` |
| **`ghc-heap`** | [`9.8.1`](http://hackage.haskell.org/package/ghc-heap-9.8.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/ghc-heap-9.8.1/src/LICENSE) | Functions for walking GHC's heap | `ghc`, `ghci` |
| **`ghc-prim`** | [`0.11.0`](http://hackage.haskell.org/package/ghc-prim-0.11.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/ghc-prim-0.11.0/src/LICENSE) | GHC primitives | *(core library)* |
| **`ghci`** | [`9.8.1`](http://hackage.haskell.org/package/ghci-9.8.1) |  *MISSING* | *MISSING* | `ghc` |
| **`hpc`** | [`0.7.0.0`](http://hackage.haskell.org/package/hpc-0.7.0.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/hpc-0.7.0.0/src/LICENSE) | Code Coverage Library for Haskell | `ghc` |
| **`mtl`** | [`2.3.1`](http://hackage.haskell.org/package/mtl-2.3.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/mtl-2.3.1/src/LICENSE) | Monad classes for transformers, using functional dependencies | `exceptions` |
| **`pretty`** | [`1.1.3.6`](http://hackage.haskell.org/package/pretty-1.1.3.6) | [`BSD-3-Clause`](http://hackage.haskell.org/package/pretty-1.1.3.6/src/LICENSE) | Pretty-printing library | `template-haskell` |
| **`process`** | [`1.6.18.0`](http://hackage.haskell.org/package/process-1.6.18.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/process-1.6.18.0/src/LICENSE) | Process libraries | `ghc` |
| **`semaphore-compat`** | [`1.0.0`](http://hackage.haskell.org/package/semaphore-compat-1.0.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/semaphore-compat-1.0.0) | Cross-platform abstraction for system semaphores | `ghc` |
| **`stm`** | [`2.5.2.1`](http://hackage.haskell.org/package/stm-2.5.2.1) | [`BSD-3-Clause`](http://hackage.haskell.org/package/stm-2.5.2.1/src/LICENSE) | Software Transactional Memory | `exceptions`, `ghc` |
| **`template-haskell`** | [`2.21.0.0`](http://hackage.haskell.org/package/template-haskell-2.21.0.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/template-haskell-2.21.0.0/src/LICENSE) | Support library for Template Haskell | `bytestring`, `containers`, `exceptions`, `filepath`, `ghc`, `ghci` |
| **`time`** | [`1.12.2`](http://hackage.haskell.org/package/time-1.12.2) | [`BSD-2-Clause`](http://hackage.haskell.org/package/time-1.12.2/src/LICENSE) | A time library | `directory`, `ghc`, `hpc`, `unix` |
| **`transformers`** | [`0.6.1.0`](http://hackage.haskell.org/package/transformers-0.6.1.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/transformers-0.6.1.0/src/LICENSE) | Concrete functor and monad transformers | `exceptions`, `ghc`, `ghci`, `mtl` |
| **`unix`** | [`2.8.3.0`](http://hackage.haskell.org/package/unix-2.8.3.0) | [`BSD-3-Clause`](http://hackage.haskell.org/package/unix-2.8.3.0/src/LICENSE) | POSIX functionality | `directory`, `ghc`, `ghc-boot`, `ghci`, `process`, `semaphore-compat` |

