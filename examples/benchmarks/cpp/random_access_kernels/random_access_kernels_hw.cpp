#include <iostream>
#include <random>
#include <cmath>
#include <string>
#include <cstdio>
#include <cstdlib>
#include <chrono>
#include <vector>
#include "experimental/xrt_xclbin.h"
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"

#define NUM_CUS 32
#define M (1 << 29)
#define CHUNK_SIZE (1 << 24)

class Timer {
private:
    std::chrono::time_point<std::chrono::high_resolution_clock> start_time;
    std::chrono::time_point<std::chrono::high_resolution_clock> stop_time;
public:
    Timer() {
        start_time = std::chrono::high_resolution_clock::now();
        stop_time = start_time;
    }

    void start() {start_time = std::chrono::high_resolution_clock::now();}
    void stop() {stop_time = std::chrono::high_resolution_clock::now();}
    double elapsed() {return std::chrono::duration<double>(stop_time - start_time).count();}
};

int main(int argc, char** argv) {
	Timer timer;
    // Open the device
	Timer device_timer;
    auto device = xrt::device(0);
	device_timer.stop();

    // Load the xclbin file
	Timer xclbin_timer;
	auto xclbin = xrt::xclbin("/dev/shm/random_access_kernels_single.xclbin");
    auto uuid = device.load_xclbin(xclbin);
	xclbin_timer.stop();

    // Create the kernel
	Timer kernel_timer;
    std::vector<xrt::kernel> kernels;

    for (int i=0; i<NUM_CUS;i++) {
        kernels.push_back(xrt::kernel(device, uuid, "accessMemory_0:{accessMemory_0_" + std::to_string(i + 1) + "}"));
    }
	kernel_timer.stop();

    // Allocate and initialize buffers
	// Host Memory pointer aligned to 4K boundary
	Timer allocation_timer;
    long data[M] = {0};
    long random_init[M];

	// Create a random number generator
	std::srand(static_cast<unsigned int>(std::time(nullptr)));

	// Sample example filling the allocated host memory
	for(int i=0; i<M; i++) {
		random_init[i] = std::rand();
	}

    std::vector<xrt::bo> data_bos;
    std::vector<xrt::bo> random_init_bos;
    for (int i=0; i<NUM_CUS; i++) {
        auto data_bo = xrt::bo(device, CHUNK_SIZE * sizeof(long), kernels[i].group_id(0));
	    auto random_init_bo = xrt::bo(device, CHUNK_SIZE * sizeof(long), kernels[i].group_id(1));

        data_bo.write(&data[i * CHUNK_SIZE], CHUNK_SIZE * sizeof(long), 0);
        random_init_bo.write(&random_init[i * CHUNK_SIZE], CHUNK_SIZE * sizeof(long), 0);

        data_bos.push_back(data_bo);
        random_init_bos.push_back(random_init_bo);
    }
	allocation_timer.stop();

    // Sync input buffer to device
	Timer syncto_timer;
    for (int i=0; i<NUM_CUS; i++) {
        data_bos[i].sync(XCL_BO_SYNC_BO_TO_DEVICE);
        random_init_bos[i].sync(XCL_BO_SYNC_BO_TO_DEVICE);
    }
	syncto_timer.stop();

    // Execute the kernel
	Timer run_timer;
    std::vector<xrt::run> runs;
    for (int i=0; i<NUM_CUS; i++) {
        runs.push_back(kernels[i](data_bos[i], random_init_bos[i], M, M / NUM_CUS, 1, i));
    }
    for (int i=0; i<NUM_CUS; i++) {
        runs[i].wait();
    }
	run_timer.stop();

    // Sync output buffer to host
	Timer syncfrom_timer;
    for (int i=0; i<NUM_CUS; i++) {
        data_bos[i].sync(XCL_BO_SYNC_BO_FROM_DEVICE);
        data_bos[i].read(&data[i * CHUNK_SIZE], CHUNK_SIZE * sizeof(long), 0);
    }
	syncfrom_timer.stop();

    // Verify results
	Timer verify_timer; 
    size_t zero_count = 0;
	for (int i=0; i<M; i++) {
		if (data[i] == 0) {
			zero_count++;
		}
    }
    if (static_cast<double>(zero_count) / M > 0.05) {
        std::cerr << "Failed" << std::endl;
		return 1;
    }
	verify_timer.stop();
	timer.stop();

	std::cout << device_timer.elapsed() << std::endl;
	std::cout << xclbin_timer.elapsed() << std::endl;
	std::cout << kernel_timer.elapsed() << std::endl;
	std::cout << allocation_timer.elapsed() << std::endl;
	std::cout << syncto_timer.elapsed() << std::endl;
	std::cout << run_timer.elapsed() << std::endl;
	std::cout << syncfrom_timer.elapsed() << std::endl;
	std::cout << verify_timer.elapsed() << std::endl;
	std::cout << timer.elapsed() << std::endl;
    return 0;
}
