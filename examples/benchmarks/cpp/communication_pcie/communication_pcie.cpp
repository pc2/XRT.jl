#include "experimental/xrt_xclbin.h"
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include "xrt/xrt_kernel.h"

#define ARRAY_SIZE 1

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
	auto xclbin = xrt::xclbin("/dev/shm/communication_PCIE.xclbin");
    auto uuid = device.load_xclbin(xclbin);
	xclbin_timer.stop();

    // Create the kernel
	Timer kernel_timer;
    auto kernel = xrt::kernel(device, uuid, "dummyKernel");
	kernel_timer.stop();

    // Allocate and initialize buffers
	// Host Memory pointer aligned to 4K boundary
	Timer allocation_timer;
	char* a;
	posix_memalign(reinterpret_cast<void**>(&a), 4096, ARRAY_SIZE * sizeof(char));

	// Sample example filling the allocated host memory
	for(int i=0; i<ARRAY_SIZE; i++) {
		a[i] = '0';
	}

	auto abo = xrt::bo(device, a, ARRAY_SIZE * sizeof(char), kernel.group_id(0));
	allocation_timer.stop();

    // Sync input buffer to device
	Timer syncto_timer;
    abo.sync(XCL_BO_SYNC_BO_TO_DEVICE);
	syncto_timer.stop();

    // Execute the kernel
	Timer run_timer;
    auto run = kernel(abo, '1', ARRAY_SIZE);
    run.wait();
	run_timer.stop();

    // Sync output buffer to host
	Timer syncfrom_timer;
    abo.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
	syncfrom_timer.stop();

    // Verify results
	Timer verify_timer; 
    for (int i=0; i<ARRAY_SIZE; i++) {
		if (a[i] != '1') {
			std::cerr << "Failed at " << i << std::endl;
			return 1;
		}
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
