# Changelog

## Unreleased

- Fixes in xrt_cxxwrap for XRT +2.20 and Windows
- Support Julia >= v1.12
- Fixes BO allocation in tests failing

## v0.2.2

- Add typecasts to the stream_fpga example
- Add check for UUID in `load_xclbin!`

## v0.2.1

- Set depth argument to integer for Documenter.jl < v1.0.0

## v0.2.0

- Add switching between XRT versions
    - Add conditional compiling to xrtwrap.cpp
- Improve detection of native XRT installation
- Add Message APIs
- Add Configuration APIs
- Add Custom IP APIs
- Add Xclbin API data type
    - Add visualize_streams function
- Add device detection
    - Support Info APIs
    - Add XilinxDevice type
- Add tabular prints for devices and Xclbin files
- Add global state type
- Move enums to submodules
- Add directional BOArrays and wrapper types
- Import @prepare_bitstream macro
    - Add type annotations
    - Support direct cu execution
    - Support directional BOArrays
- Add @sync_buffers macro
- Add @prepare_run macro
- Add xbutil/xclbinutil support
- Reexport ArrayAllocators.jl
- Add unit- and integration tests
- Add benchmarks for C/C++/Rust/Python/Julia
- Update docs

## v0.1.4

- Fix order of BO arguments in BOArray constructor which lead to allocation errors
- Convert prepare_bitstream function to macro and fix signature generation
- Minor changes in method names (adding ! to some methods because they change their input parameters)
- Move wrapped API to XRTWrap submodule to support easier extension of core functionality
- Use CMake module instead of OS cmake, full CMake workflow including install, add uuid link library

## v0.1.3

- Add Libuuid_jll as dependency to not require uuid to be installed on host system

## v0.1.2

- Add ! to the names of generated functions of prepare_bitstream

## v0.1.1

- Provide build-in XRT libraries using BinaryBuilder.jl

## v0.1.0

- Initial version
