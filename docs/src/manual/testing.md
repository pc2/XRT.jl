# Testing of XRT.jl

XRT.jl comes with a little test environment, whose unit and integration tests are intended to ensure correct execution.
To display the help page of the test environment, the `runtests.jl` file is called with the `--help` flag.
Alternatively, the page can be called up using the `Pkg.test` function and the `test_args` keyword:

```Julia
julia> using Pkg; Pkg.test("XRT", test_args=["--help"])
Usage: runtests.jl [--help] [--quick] [--verbose]

        --help             Show this text.
        --quick            Skip long tests.
        --verbose          Print more information during testing.
```

By default, the test environment also runs all precompiled device tests provided by `xbutil validate` on all available devices.
These tests can take several hours, depending on the system, and can therefore be skipped by declaring the `--quick` flag.
The test environment will then simply call `xbutil validate -r quick` instead of `-r all`, which only executes the first four precompiled tests and saves a lot of time.

In order to test Xclbin file handling and kernel execution on a device, a valid specific Xclbin file has to be present on the system.
The test environment checks whether the [Example: STREAM Benchmark](@ref) bitstream is built and available in the default build directory for the selected emulation mode, and uses that for its following tests.
However, these are skipped if the file is not available.

There are also some tests that require multiple available Xilinx devices.
However, these are also skipped if there are not enough devices available.
