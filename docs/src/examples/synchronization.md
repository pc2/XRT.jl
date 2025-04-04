# Example: Automatic Buffer Synchronization

The following executions use the *STREAM* benchmark kernel.
See [Example: STREAM Benchmark](@ref) for details and building of the bitstream.

The kernel's first compute unit can be executed with automatic synchronization of the buffers as follows:

```Julia
array_size = 2^20

a = Array{Float64}(MemAlign(4096), array_size)
b = Array{Float64}(MemAlign(4096), array_size)
c = Array{Float64}(MemAlign(4096), array_size)

a[:] .= rand(array_size)
b[:] .= rand(array_size)
c[:] .= 0

uuid = load_xclbin!("stream.xclbin")
stream = XRT.Kernel(uuid, "stream_calc:{k1}")

xa = XRT.BOArray(a, group_id(stream, 0))
xb = XRT.BOArray(b, group_id(stream, 1))
xc = XRT.BOArray(c, group_id(stream, 2))

XRT.@sync_buffers XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1)

a[:] .= xa[:]
b[:] .= xb[:]
c[:] .= xc[:]

@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
```

This code snippet synchronizes all buffers to and from the device.
To differ between input and output buffers the `XRT.BOArray` can be replaced with directional `XRT.ToDeviceBOArray` and `XRT.ToDeviceBOArray`:

```Julia
xa = XRT.ToDeviceBOArray(a, group_id(stream, 0))
xb = XRT.ToDeviceBOArray(b, group_id(stream, 1))
xc = XRT.FromDeviceBOArray(c, group_id(stream, 2))
```

Alternatively, the BOArrays can continue to be used, but the synchronization to the host can be handled manually instead.
The `XRT.@sync_buffers` macro can only synchronize the buffers in one direction to the device:

```Julia
XRT.@sync_buffers direction=XRT.TO_DEVICE r = XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1)
# In this case the `wait` call is explicitly need
wait(r)

sync!(xc, XRT.FROM_DEVICE)
c[:] .= xc[:]

@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
```

## Parallel kernel execution

The automatic buffer synchronization can also be used when running kernels in parallel on multiple FPGAs.
The STREAM kernel consists of two compute units.
It is possible to run both in parallel on different FPGAs:

```Julia
array_size = 2^20

a1 = Array{Float64}(MemAlign(4096), array_size)
b1 = Array{Float64}(MemAlign(4096), array_size)
c1 = Array{Float64}(MemAlign(4096), array_size)

a2 = Array{Float64}(MemAlign(4096), array_size)
b2 = Array{Float64}(MemAlign(4096), array_size)
c2 = Array{Float64}(MemAlign(4096), array_size)

a1[:] .= rand(array_size)
b1[:] .= rand(array_size)
c1[:] .= 0

a2[:] .= rand(array_size)
b2[:] .= rand(array_size)
c2[:] .= 0

uuid1 = load_xclbin!("stream.xclbin"; device=XRT.device(1))
k1 = XRT.Kernel(uuid, "stream_calc:{k1}")

uuid2 = load_xclbin!("stream.xclbin"; device=XRT.device(2))
k2 = XRT.Kernel(uuid, "stream_calc:{k2}")

xa1 = XRT.BOArray(a1, group_id(k1, 0))
xb1 = XRT.BOArray(b1, group_id(k1, 1))
xc1 = XRT.BOArray(c1, group_id(k1, 2))

xa2 = XRT.BOArray(a2, group_id(k2, 0))
xb2 = XRT.BOArray(b2, group_id(k2, 1))
xc2 = XRT.BOArray(c2, group_id(k2, 2))

XRT.@sync_buffers begin
    XRT.Run(k1, xa1, xb1, xc1, 2.0, array_size, 1)
    XRT.Run(k2, xa2, xb2, xc2, 2.0, array_size, 1)
    end

a1[:] .= xa1[:]
b1[:] .= xb1[:]
c1[:] .= xc1[:]

a2[:] .= xa2[:]
b2[:] .= xb2[:]
c2[:] .= xc2[:]

@test all(.≈(c1, 2 .* a1 .+ b1, atol = 0.01))

@test all(.≈(c2, 2 .* a2 .+ b2, atol = 0.01))
```