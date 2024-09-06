# Changelog

## Unreleased

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
