import time

start_time = time.perf_counter()
import pynq
import numpy as np

overlay_start_time = time.perf_counter()
ol = pynq.Overlay("/dev/shm/communication_PCIE.xclbin")
overlay_end_time = time.perf_counter()

allocation_start_time = time.perf_counter()
ARRAY_SIZE = 1
a = pynq.allocate((ARRAY_SIZE,), dtype='uint8', target=ol.bank0)
a[:] = 0
allocation_end_time = time.perf_counter()

syncto_start_time = time.perf_counter()
a.sync_to_device()
syncto_end_time = time.perf_counter()

run_start_time = time.perf_counter()
ol.dummyKernel.call(a, bytes([1]), ARRAY_SIZE)
run_end_time = time.perf_counter()

syncfrom_start_time = time.perf_counter()
a.sync_from_device()
syncfrom_end_time = time.perf_counter()

verify_start_time = time.perf_counter()
assert all(a[i] == 1 for i in range(ARRAY_SIZE))
verify_end_time = time.perf_counter()
end_time = time.perf_counter()

print(overlay_end_time - overlay_start_time)
print(allocation_end_time - allocation_start_time)
print(syncto_end_time - syncto_start_time)
print(run_end_time - run_start_time)
print(syncfrom_end_time - syncfrom_start_time)
print(verify_end_time - verify_start_time)
print(end_time - start_time)
