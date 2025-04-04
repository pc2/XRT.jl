import time

start_time = time.perf_counter()
import pynq
import math
import numpy as np

overlay_start_time = time.perf_counter()
ol = pynq.Overlay("/dev/shm/stream.xclbin")
overlay_end_time = time.perf_counter()

allocation_start_time = time.perf_counter()
ARRAY_SIZE = 2 ** 28

a = pynq.allocate((ARRAY_SIZE,), np.float64, target=ol.bank0)
b = pynq.allocate((ARRAY_SIZE,), np.float64, target=ol.bank0)
c = pynq.allocate((ARRAY_SIZE,), np.float64, target=ol.bank0)

a[:] = np.random.rand(ARRAY_SIZE).astype(np.float64)
b[:] = np.random.rand(ARRAY_SIZE).astype(np.float64)
c[:] = 0.0
allocation_end_time = time.perf_counter()

syncto_start_time = time.perf_counter()
a.sync_to_device()
b.sync_to_device()
syncto_end_time = time.perf_counter()

run_start_time = time.perf_counter()
ol.k1.call(a, b, c, 2.0, ARRAY_SIZE, 1)
run_end_time = time.perf_counter()

syncfrom_start_time = time.perf_counter()
c.sync_from_device()
syncfrom_end_time = time.perf_counter()

verify_start_time = time.perf_counter()
assert all(math.isclose(c[i], 2.0 * a[i] + b[i], abs_tol=0.01) for i in range(ARRAY_SIZE))
verify_end_time = time.perf_counter()
end_time = time.perf_counter()

print(overlay_end_time - overlay_start_time)
print(allocation_end_time - allocation_start_time)
print(syncto_end_time - syncto_start_time)
print(run_end_time - run_start_time)
print(syncfrom_end_time - syncfrom_start_time)
print(verify_end_time - verify_start_time)
print(end_time - start_time)
