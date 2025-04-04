@xclbin_testset "Execute native API" begin
	array_size = 2^20

	a = Array{Float64}(MemAlign(4096),array_size)
	b = Array{Float64}(MemAlign(4096),array_size)
	c = Array{Float64}(MemAlign(4096),array_size)

	a[:] .= rand(array_size)
	b[:] .= rand(array_size)
	c[:] .= 0

	d = XRT.device(1).device
	uuid = load_xclbin!(d, path)
	stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

	xa = XRT.BOArray(d, a, group_id(stream, 0))
	xb = XRT.BOArray(d, b, group_id(stream, 1))
	xc = XRT.BOArray(d, c, group_id(stream, 2))

	sync!(xa, XRT.TO_DEVICE)
	sync!(xb, XRT.TO_DEVICE)
	sync!(xc, XRT.TO_DEVICE)

	r = XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1)
	XRT.wait(r)

	sync!(xa, XRT.FROM_DEVICE)
	sync!(xb, XRT.FROM_DEVICE)
	sync!(xc, XRT.FROM_DEVICE)

	a[:] .= xa[:]
	b[:] .= xb[:]
	c[:] .= xc[:]

	@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
end

@xclbin_testset "@sync_buffers" begin
	array_size = 2^20

	a = Array{Float64}(MemAlign(4096),array_size)
	b = Array{Float64}(MemAlign(4096),array_size)
	c = Array{Float64}(MemAlign(4096),array_size)

	@testset "Execute @sync_buffers macro" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.BOArray(d, a, group_id(stream, 0))
		xb = XRT.BOArray(d, b, group_id(stream, 1))
		xc = XRT.BOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1)

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @sync_buffers macro with direction" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.BOArray(d, a, group_id(stream, 0))
		xb = XRT.BOArray(d, b, group_id(stream, 1))
		xc = XRT.BOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers direction=XRT.TO_DEVICE XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1)

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.==(c, 0.0))
	end

	@testset "Execute @sync_buffers XRT.XRTWrap.Run" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.BOArray(d, a, group_id(stream, 0))
		xb = XRT.BOArray(d, b, group_id(stream, 1))
		xc = XRT.BOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers XRT.XRTWrap.Run(stream, xa, xb, xc, 2.0, array_size, 1)

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @sync_buffers imported Run" begin
		import XRT: Run

		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.BOArray(d, a, group_id(stream, 0))
		xb = XRT.BOArray(d, b, group_id(stream, 1))
		xc = XRT.BOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers Run(stream, xa, xb, xc, 2.0, array_size, 1)

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @sync_buffers wait(Run)" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.BOArray(d, a, group_id(stream, 0))
		xb = XRT.BOArray(d, b, group_id(stream, 1))
		xc = XRT.BOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers wait(XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1))

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @sync_buffers block" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.BOArray(d, a, group_id(stream, 0))
		xb = XRT.BOArray(d, b, group_id(stream, 1))
		xc = XRT.BOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers begin
			r = XRT.XRTWrap.Run(stream, xa, xb, xc, 2.0, array_size, 1)
			end

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @sync_buffers macro with SyncDirectionArrays" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		d = XRT.device(1).device
		uuid = load_xclbin!(d, path)
		stream = XRT.Kernel(d, uuid, "stream_calc:{k1}")

		xa = XRT.ToDeviceBOArray(d, a, group_id(stream, 0))
		xb = XRT.ToDeviceBOArray(d, b, group_id(stream, 1))
		xc = XRT.FromDeviceBOArray(d, c, group_id(stream, 2))

		XRT.@sync_buffers XRT.Run(stream, xa, xb, xc, 2.0, array_size, 1)

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]

		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end
end

@xclbin_testset "@prepare_bitstream" begin
	@eval @prepare_bitstream($path)
	array_size = 2^20

	@testset "Execute @prepare_bitstream" begin
		a = Array{Float64}(MemAlign(4096),array_size)
		b = Array{Float64}(MemAlign(4096),array_size)
		c = Array{Float64}(MemAlign(4096),array_size)
		
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0
		
		stream_calc__k1!(a, b, c, 2.0, UInt32(array_size), UInt32(1))
		
		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @prepare_bitstream SyncDirectionArrays" begin
		a = ToDeviceArray{Float64}(MemAlign(4096),array_size)
		b = ToDeviceArray{Float64}(MemAlign(4096),array_size)
		c = FromDeviceArray{Float64}(MemAlign(4096),array_size)
		
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0
		
		stream_calc__k1!(a, b, c, 2.0, UInt32(array_size), UInt32(1))
		
		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

	@testset "Execute @prepare_bitstream wrapped arrays" begin
		a = Array{Float64}(MemAlign(4096),array_size)
		b = Array{Float64}(MemAlign(4096),array_size)
		c = Array{Float64}(MemAlign(4096),array_size)
		
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0
		
		stream_calc__k1!(XRT.ToDeviceWrapper(a), XRT.ToDeviceWrapper(b), XRT.FromDeviceWrapper(c), 2.0, UInt32(array_size), UInt32(1))
		
		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))
	end

end

@xclbin_testset "@prepare_run" begin
	kernel, uuid = @eval @prepare_run($path, "stream_calc")

	@test typeof(kernel) == XRT.XRTWrap.KernelAllocated
	@test typeof(uuid) == XRT.XRTWrap.UUIDAllocated

	array_size = 2^20

	a = Array{Float64}(MemAlign(4096), array_size)
	b = Array{Float64}(MemAlign(4096), array_size)
	c = Array{Float64}(MemAlign(4096), array_size)

	@testset "Execute @prepare_run macro" begin
		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		xa = XRT.ToDeviceBOArray(a, group_id(kernel, 0))
		xb = XRT.ToDeviceBOArray(b, group_id(kernel, 1))
		xc = XRT.FromDeviceBOArray(c, group_id(kernel, 2))

		sync!(xa, XRT.TO_DEVICE)
		sync!(xb, XRT.TO_DEVICE)
		sync!(xc, XRT.TO_DEVICE)
		
		r = Run_stream_calc(xa, xb, xc, 2.0, UInt32(array_size), UInt32(1))
		wait(r)

		sync!(xa, XRT.FROM_DEVICE)
		sync!(xb, XRT.FROM_DEVICE)
		sync!(xc, XRT.FROM_DEVICE)

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]
		
		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))

	end


	@testset "Execute @prepare_run @sync_buffers macro" begin
		kernel, uuid = @eval @prepare_run($path, "stream_calc")
		array_size = 2^20

		a = Array{Float64}(MemAlign(4096), array_size)
		b = Array{Float64}(MemAlign(4096), array_size)
		c = Array{Float64}(MemAlign(4096), array_size)

		a[:] .= rand(array_size)
		b[:] .= rand(array_size)
		c[:] .= 0

		xa = XRT.ToDeviceBOArray(a, group_id(kernel, 0))
		xb = XRT.ToDeviceBOArray(b, group_id(kernel, 1))
		xc = XRT.FromDeviceBOArray(c, group_id(kernel, 2))
		
		XRT.@sync_buffers Run_stream_calc(xa, xb, xc, 2.0, UInt32(array_size), UInt32(1))

		a[:] .= xa[:]
		b[:] .= xb[:]
		c[:] .= xc[:]
		
		@test all(.≈(c, 2 .* a .+ b, atol = 0.01))

	end
end