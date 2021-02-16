# cxxtp - C++ template project

This repository is a template for C++ projects with CMake as build system.

> The project follows the CMake guidelines provided at
> https://github.com/sblumentritt/coding_guidelines.

## Requirements

- [CMake][] >= 3.17.0

**Optional**:

- [Doxygen][] - documentation generator
- [Cppcheck][] - static analysis tool for C++
- [clang-tidy][] - clang-based C++ 'linter' tool
- [clang-format][] - clang-based code formatting tool

## TODO

- [ ] Add generation/option for test related files and targets
- [ ] Add option to generate backend and frontend targets directly (lib + exe)
- [x] Allow the initialization without Git (Submodules as final info message)
- [ ] Share duplicated CMake code (e.g. `configure_target`)
- [ ] Let user specify all Git options, e.g. signing (add wait after `git init`)

## License

The project is licensed under the MIT license. See [LICENSE](LICENSE) for more
information.

[GCC]: https://gcc.gnu.org/
[CMake]: https://cmake.org/
[Clang]: https://clang.llvm.org/
[Doxygen]: http://www.stack.nl/~dimitri/doxygen/index.html
[Cppcheck]: http://cppcheck.sourceforge.net/
[clang-tidy]: http://clang.llvm.org/extra/clang-tidy/
[clang-format]: https://clang.llvm.org/docs/ClangFormat.html
