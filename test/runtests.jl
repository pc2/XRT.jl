using Test
using XRT
using ArrayAllocators

d = XRT.Device(0)

b = XRT.BO(d, 2000, 0)
@test typeof(b) == XRT.XRTWrap.BOAllocated

localbuf = rand(100)
@test_warn "User buffer not aligned. Create aligned copy!" XRT.BOArray(d, localbuf, 0)
b2 = XRT.BOArray(d, localbuf, 0)
@test typeof(b2) == XRT.BOArray{Float64, 1}

alignedbuf = Array{Float64}(MemAlign(4096), 100, 100)
alignedbuf .= rand(size(alignedbuf))
b3 = XRT.BOArray(d, alignedbuf, 0)
@test typeof(b3) == XRT.BOArray{Float64, 2}
@test length(b3) == 10000
@test size(b3) == (100,100)


@test b3[1] == alignedbuf[1]

alignedbuf[10] = 5.0
@test b3[10] == 5.0

b3[15] = 2.5
@test alignedbuf[15] == 2.5



