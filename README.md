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

- [ ] Move Catch2 target creation to a CMake helper file
- [x] Add coverage reports to the specification test target
- [ ] Share duplicated CMake code (e.g. `configure_target`)

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
