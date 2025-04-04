#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>
#include <uuid/uuid.h>
#include "experimental/xrt_xclbin.h"
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"

#define ARRAY_SIZE (1 << 28)

typedef struct Timer {
    struct timeval start_time;
    struct timeval stop_time;
} Timer;

void timer_start(struct Timer* timer) {
    gettimeofday(&timer->start_time, NULL);
}

void timer_stop(struct Timer* timer) {
    gettimeofday(&timer->stop_time, NULL);
}

double timer_elapsed(struct Timer* timer) {
    return (timer->stop_time.tv_sec - timer->start_time.tv_sec) + (timer->stop_time.tv_usec - timer->start_time.tv_usec) / 1000000.0;
}

int main(int argc, char** argv) {
    Timer timer;
    timer_start(&timer);

    // Open the device
    Timer device_timer;
    timer_start(&device_timer);
    xrtDeviceHandle device = xrtDeviceOpen(0);
    timer_stop(&device_timer);

    // Load the xclbin file
    Timer xclbin_timer;
    timer_start(&xclbin_timer);
    xrtDeviceLoadXclbinFile(device, "/dev/shm/stream.xclbin");
    uuid_t uuid;
    xrtDeviceGetXclbinUUID(device, uuid);
    timer_stop(&xclbin_timer);

    // Create the kernel
    Timer kernel_timer;
    timer_start(&kernel_timer);
    xrtKernelHandle kernel = xrtPLKernelOpen(device, uuid, "stream_calc:{k1}");
    timer_stop(&kernel_timer);

    // Allocate and initialize buffers
    Timer allocation_timer;
    timer_start(&allocation_timer);
    double* a = NULL;
    posix_memalign((void**)&a, 4096, ARRAY_SIZE * sizeof(double));
    double* b = NULL;
    posix_memalign((void**)&b, 4096, ARRAY_SIZE * sizeof(double));
    double* c = NULL;
    posix_memalign((void**)&c, 4096, ARRAY_SIZE * sizeof(double));

    srand(time(NULL));

    for (int i = 0; i < ARRAY_SIZE; i++) {
        a[i] = (double)rand() / RAND_MAX;
        b[i] = (double)rand() / RAND_MAX;
        c[i] = 0.0;
    }

    xrtBufferHandle abo = xrtBOAllocUserPtr(device, a, ARRAY_SIZE * sizeof(double), XRT_BO_FLAGS_NONE, xrtKernelArgGroupId(kernel, 0));
    xrtBufferHandle bbo = xrtBOAllocUserPtr(device, b, ARRAY_SIZE * sizeof(double), XRT_BO_FLAGS_NONE, xrtKernelArgGroupId(kernel, 1));
    xrtBufferHandle cbo = xrtBOAllocUserPtr(device, c, ARRAY_SIZE * sizeof(double), XRT_BO_FLAGS_NONE, xrtKernelArgGroupId(kernel, 2));
    timer_stop(&allocation_timer);

    // Sync input buffer to device
    Timer syncto_timer;
    timer_start(&syncto_timer);
    xrtBOSync(abo, XCL_BO_SYNC_BO_TO_DEVICE, ARRAY_SIZE * sizeof(double), 0);
    xrtBOSync(bbo, XCL_BO_SYNC_BO_TO_DEVICE, ARRAY_SIZE * sizeof(double), 0);
    timer_stop(&syncto_timer);

    // Execute the kernel
    Timer run_timer;
    timer_start(&run_timer);
    xrtRunHandle run = xrtKernelRun(kernel, abo, bbo, cbo, 2.0, ARRAY_SIZE, 1);
    xrtRunWait(run);
    timer_stop(&run_timer);

    // Sync output buffer to host
    Timer syncfrom_timer;
    timer_start(&syncfrom_timer);
    xrtBOSync(cbo, XCL_BO_SYNC_BO_FROM_DEVICE, ARRAY_SIZE * sizeof(double), 0);
    timer_stop(&syncfrom_timer);

    // Verify results
    Timer verify_timer;
    timer_start(&verify_timer);
    for (int i = 0; i < ARRAY_SIZE; i++) {
        if (fabs(c[i] - (2.0 * a[i] + b[i])) > 0.01) {
            fprintf(stderr, "Failed at %d\n", i);
            return 1;
        }
    }
    timer_stop(&verify_timer);
    timer_stop(&timer);

    printf("%.6f\n", timer_elapsed(&device_timer));
    printf("%.6f\n", timer_elapsed(&xclbin_timer));
    printf("%.6f\n", timer_elapsed(&kernel_timer));
    printf("%.6f\n", timer_elapsed(&allocation_timer));
    printf("%.6f\n", timer_elapsed(&syncto_timer));
    printf("%.6f\n", timer_elapsed(&run_timer));
    printf("%.6f\n", timer_elapsed(&syncfrom_timer));
    printf("%.6f\n", timer_elapsed(&verify_timer));
    printf("%.6f\n", timer_elapsed(&timer));
    return 0;
}