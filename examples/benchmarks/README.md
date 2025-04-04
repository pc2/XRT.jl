# Example: Benchmarks

The following examples contain benchmarks that are used the compare the host codes performance for several interfaces.
Every implementation measures its runtime as well as the runtime divided on the single stages of the kernel execution process.
The bash script of each implementation is used to run the implementation 100 times and print the measured results into a csv file.

## Benchmarks

**Note: The Xclbin files for the Communication PCIe Dummy Kernel and for the Random Access Kernel need to be copied to this directory! The STREAM Triad Xclbin is taken from the `../stream/build_[hw|sw_emu]` directory. XRT.jl needs to be precompiled using a native XRT v2.14 installation.**

### Communication PCIe Dummy Kernel

The Dummy Kernel is a very simple HLS kernel that replaces char in a given array.

```C++
void dummyKernel(char* a, char validate, int count) {
    for (int i=0; i<count; i++) {
        a[i] = validate;
    }
}
```

It is executed with an array length of one.

### STREAM Triad Kernel

Most of the benchmarks use the [STREAM Triad Kernel](https://github.com/pc2/HPCC_FPGA/tree/master/STREAM) which performs the `copy`, `scale`, `add`, and `triad` operations on two input arrays and returns the result in another output array.

The HLS kernel is also provided in the repository.
See [Example: STREAM Benchmark](../stream/README.md) on how to synthesize and run it.
Some of the built-in tests are also executed on the STREAM kernel and therefore require a built Xclbin to run.

### Random Access Kernels

As another example the [Random Access](https://github.com/pc2/HPCC_FPGA/tree/master/RandomAccess) benchmark is executed on 32 compute units in parallel on one device.
A simple host implementation is provided in C++ and Julia.
