
#define BUFFER_SIZE 4096
#define UNROLL_COUNT 8

void stream_calc(const double *in1, const double *in2, double *out,
                 const double scalar, const unsigned int number_elements,
                 const unsigned int second_input) {
    // Process every element in the global memory arrays by loading chunks of
    // data that fit into the local memory buffer
    for (unsigned int i = 0; i < number_elements; i += BUFFER_SIZE) {
        double buffer1[BUFFER_SIZE];

        // Load chunk of first array into buffer and scale the values
        for (unsigned int k = 0; k < BUFFER_SIZE; k += UNROLL_COUNT) {
            // Registers used to store the values for all unrolled
            // load operations from global memory
            double chunk[UNROLL_COUNT];

            // Load values from global memory into the registers
            // The number of values is defined by UNROLL_COUNT
            for (unsigned int u = 0; u < UNROLL_COUNT; u++) {
                chunk[u] = in1[i + k + u];
            }

            // Scale the values in the registers and store the
            // result in the local memory buffer
            for (unsigned int u = 0; u < UNROLL_COUNT; u++) {
                buffer1[k + u] = scalar * chunk[u];
            }
        }
        // optionally load chunk of second array into buffer for add and triad
        if (second_input) {
            for (unsigned int k = 0; k < BUFFER_SIZE; k += UNROLL_COUNT) {
                // Registers used to store the values for all unrolled
                // load operations from global memory
                double chunk[UNROLL_COUNT];

                // Load values from global memory into the registers
                // The number of values is defined by UNROLL_COUNT
                for (unsigned int u = 0; u < UNROLL_COUNT; u++) {
                    chunk[u] = in2[i + k + u];
                }

                // Add the values in the registers to the
                // values stored in local memory
                for (unsigned int u = 0; u < UNROLL_COUNT; u++) {
                    buffer1[k + u] += chunk[u];
                }
            }
        }

        // Read the cumputed chunk of the output array from local memory
        // and store it in global memory
        for (unsigned int k = 0; k < BUFFER_SIZE; k += UNROLL_COUNT) {
            // Registers used to store the values for all unrolled
            // load operations from local memory
            double chunk[UNROLL_COUNT];

            // Load values from local memory into the registers
            // The number of values is defined by UNROLL_COUNT
            for (unsigned int u = 0; u < UNROLL_COUNT; u++) {
                chunk[u] = buffer1[k + u];
            }

            // Store the values in the registers in global memory
            for (unsigned int u = 0; u < UNROLL_COUNT; u++) {
                out[i + k + u] = chunk[u];
            }
        }
    }
}