# Example: STREAM Benchmark

This example contains a C++ HLS implementation of the STREAM benchmark for the DDR memory banks of the Alveo U280 board.
The kernel can be used to execute all four STREAM kernels `copy`, `scale`, `add`, and `triad` by setting the input parameters accordingly.

## Implementation Details

The signature of the HLS stream kernels looks like the following:

```C++
void stream_calc(const double *in1, const double *in2, double *out,
                 const double scalar, const unsigned int number_elements,
                 const unsigned int second_input)
```

When executed, the kernel will multiply all values in the buffer `in1` with the scalar value given in `scalar`. The array length is given by the input parameter `number_elements` and is the same for all input and output arrays. If `second_input` > 0, also the second input array `in2` will be processed and added to the result of scaling array `in1`. The final result will be stored in the array `out`.

In our example code, we will execute the `triad` kernel of the STREAM benchmark and measure the total execution time of the kernel.
Since we are using the high-level wrapper to create our kernel method, all buffers will be read and written to and from the FPGA before the actual kernel execution. 

## Building

To execute this example, Vitis HLS needs to be installed on the system.
The FPGA bitstream first has to be build using the provided Makefile. 
A emulation target can be specified using the `TARGET` parameter to build for software emulation (`sw_emu`), hardware emulation (`hw_emu`), or hardware (`hw`). To build the bitstream for software emulation for the Alveo U280, run the following command:

    make all TARGET=sw_emu

After successful build, the julia code can be executed:

    env XCL_EMULATION_MODE=sw_emu julia --project stream_fpga.jl

The output should look similar to this:

    Kernel Name: k1, CU Number: 0, Thread creation status: success
    Kernel Name: k2, CU Number: 1, Thread creation status: success
    [ Info: Execute kernel test run
    Kernel Name: k1, CU Number: 0, State: Start
    Kernel Name: k1, CU Number: 0, State: Running
    Kernel Name: k1, CU Number: 0, State: Idle
    [ Info: Execute full kernel run TRIAD
    Kernel Name: k1, CU Number: 0, State: Start
    Kernel Name: k1, CU Number: 0, State: Running
    Kernel Name: k1, CU Number: 0, State: Idle
    [ Info: Execution time: 0.148555856 seconds
    [ Info: Measured bandwidth: 0.5082093296948187 GB/s
    [ Info: Validate output
    [ Info: Done
    device process sw_emu_device done
    Kernel Name: k1, CU Number: 0, Status: Shutdown
    Kernel Name: k2, CU Number: 1, Status: Shutdown

Note, that the measured bandwidth is relatively low because software emulation is used.
To execute the stream benchmark on hardware, the path to the bitstream has to be changed accordingly by updating the `bitstream()` function.