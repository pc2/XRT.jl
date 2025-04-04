xd = XRT.device(1)

@testset "BO" begin
    b = XRT.BO(xd.device, 2000, 0)
    @test typeof(b) == XRT.XRTWrap.BOAllocated
    @test XRT.XRTWrap.length(b) == 2000
    @test typeof(XRT.XRTWrap.get_flags(b)) == XRT.XRTWrap.BOFlags.Type
end

@testset "BOArray" begin
    localbuf = rand(100)
    @test_warn "User buffer not aligned. Create aligned copy!" XRT.BOArray(xd.device, localbuf, 0)
    b2 = XRT.BOArray(xd.device, localbuf, 0)
    @test typeof(b2) == XRT.BOArray{Float64, 1}
	@test XRT.address(b2) == 8192 || XRT.address(b2) == 4096
	@test XRT.get_memory_group(b2) == 0
	@test XRT.get_flags(b2) == XRT.BOFlags.NORMAL

    alignedbuf = Array{Float64}(MemAlign(4096), 100, 100)
    alignedbuf .= rand(size(alignedbuf))
    b3 = XRT.BOArray(alignedbuf, 0; device=xd)
    @test typeof(b3) == XRT.BOArray{Float64, 2}
    @test length(b3) == 10000
    @test size(b3) == (100,100)

    @test b3[1] == alignedbuf[1]

    alignedbuf[10] = 5.0
    @test b3[10] == 5.0

    b3[15] = 2.5
    @test alignedbuf[15] == 2.5
end

@testset "SyncDirectionArray" begin
	array_size = 2000
	
	@testset "ToDeviceArray" begin
		a = zeros(Float64, array_size)
		tda = ToDeviceArray(a)
		@test typeof(tda) == ToDeviceArray{Float64}
		@test length(tda) == array_size
		@test size(tda) == (array_size,)
		tda[150] = 1
		@test tda[150] == 1.0
	end
	
	@testset "Aligned ToDeviceArray" begin
		aligned_tda = ToDeviceArray{Float64}(MemAlign(4096), array_size)
		@test typeof(aligned_tda) == ToDeviceArray{Float64}
		@test length(aligned_tda) == array_size
		@test size(aligned_tda) == (array_size,)
		aligned_tda[150] = 1
		@test aligned_tda[150] == 1.0
		
		b = XRT.AbstractBOArray(aligned_tda, 0, device=xd)
		@test typeof(b) == XRT.ToDeviceBOArray{Float64, 1}
	end
	
	@testset "FromDeviceArray" begin
		a = zeros(Float64, array_size)
		tda = FromDeviceArray(a)
		@test typeof(tda) == FromDeviceArray{Float64}
		@test length(tda) == array_size
		@test size(tda) == (array_size,)
		tda[150] = 1
		@test tda[150] == 1.0		
	end
	
	@testset "Aligned FromDeviceArray" begin
		aligned_tda = FromDeviceArray{Float64}(MemAlign(4096), array_size)
		@test typeof(aligned_tda) == FromDeviceArray{Float64}
		@test length(aligned_tda) == array_size
		@test size(aligned_tda) == (array_size,)
		aligned_tda[150] = 1
		@test aligned_tda[150] == 1.0
		
		b = XRT.AbstractBOArray(aligned_tda, 0, device=xd)
		@test typeof(b) == XRT.FromDeviceBOArray{Float64, 1}
	end
	
end
