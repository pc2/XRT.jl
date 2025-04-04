use xrt::ffi::XCL_BO_FLAGS_NONE;
use xrt::native::buffer::SyncDirection;
use xrt::native::buffer::XRTBuffer;
use xrt::native::device::XRTDevice;
use xrt::native::kernel::XRTKernel;
use xrt::native::run::ERTCommandState;
use xrt::native::run::XRTRun;
use xrt::Result;
use std::time::Instant;

fn main() -> Result<()> {
    let start_time = Instant::now();
    // Open the device
    let device_start_time = Instant::now();
    let mut device = XRTDevice::try_from(0)?;
    let device_end_time = device_start_time.elapsed();

    // Load the xclbin file
    let loadxclbin_start_time = Instant::now();
    let _uuid = device.load_xclbin("/dev/shm/communication_PCIE.xclbin");
    let loadxclbin_end_time = loadxclbin_start_time.elapsed();

    // Create the kernel
    let kernel_start_time = Instant::now();
    let kernel = XRTKernel::new("dummyKernel", &device)?;
    let kernel_end_time = kernel_start_time.elapsed();

    // Allocate buffers
    let allocation_start_time = Instant::now();
    const ARRAY_SIZE: usize = 1;
    let mut a: [u8; ARRAY_SIZE] = [0; ARRAY_SIZE];

    let a_buffer = XRTBuffer::new(&device, ARRAY_SIZE * std::mem::size_of::<u8>(), XCL_BO_FLAGS_NONE, kernel.get_memory_group_for_argument(0)?,)?;
    let allocation_end_time = allocation_start_time.elapsed();

    let syncto_start_time = Instant::now();
    a_buffer.write(&a, 0)?;
    a_buffer.sync::<f64>(SyncDirection::HostToDevice, None, 0)?;
    let syncto_end_time = syncto_start_time.elapsed();

    // Run
    let run_start_time = Instant::now();
    let run = XRTRun::try_from(&kernel)?;
    run.set_buffer_argument(0, &a_buffer)?;
    run.set_scalar_argument(1, 1 as u8)?;
    run.set_scalar_argument(2, ARRAY_SIZE)?;

    let _start_state = run.start()?;
    let result_state = run.wait()?;
    assert_eq!(result_state, ERTCommandState::Completed);
    let run_end_time = run_start_time.elapsed();

    // Get back data
    let syncfrom_start_time = Instant::now();
    a_buffer.sync::<f64>(SyncDirection::DeviceToHost, None, 0)?;
    a_buffer.read(&mut a, 0)?;
    let syncfrom_end_time = syncfrom_start_time.elapsed();

    // Verify results
    let verify_start_time = Instant::now();
    for i in 0..ARRAY_SIZE {
        assert!(a[i] == 1u8);
    }
    let verify_end_time = verify_start_time.elapsed();
    let end_time = start_time.elapsed();

    println!("{}", device_end_time.as_secs_f64());
    println!("{}", loadxclbin_end_time.as_secs_f64());
    println!("{}", kernel_end_time.as_secs_f64());
    println!("{}", allocation_end_time.as_secs_f64());
    println!("{}", syncto_end_time.as_secs_f64());
    println!("{}", run_end_time.as_secs_f64());
    println!("{}", syncfrom_end_time.as_secs_f64());
    println!("{}", verify_end_time.as_secs_f64());
    println!("{}", end_time.as_secs_f64());

    Ok(())
}
