using .XRTWrap: IP, write_register!, read_register, create_interrupt_notify
using .XRTWrap: IPInterrupt, enable!, disable!, wait

"""
```Julia
IP(uuid::XRT.XRTWrap.UUID, name::AbstractString; device::XilinxDevice=device())

```

Create a new custom IP instance using a `XilinxDevice`, bitstream uuid, and kernel name.
The target device can be changed by setting the `device` keyword parameter.
"""
function IP(uuid::UUID, name::AbstractString; device::XilinxDevice=device())
    IP(device.device, uuid, name)
end

@doc """
```Julia
write_register!(ip::XRT.XRTWrap.IP, offset::Integer, data::Integer)

```

Write data to the address range of an IP.
""" write_register!

@doc """
```Julia
read_register(ip::XRT.XRTWrap.IP, offset::Integer)

```

Read data from IP address range.
""" read_register

@doc """
```Julia
create_interrupt_notify(ip::XRT.XRTWrap.IP)

```

Creates an `XRT.IPInterrupt` object that can be used to control and wait for IP interrupt when IP supports interrupts.
The interrupt is automatically enabled.
""" create_interrupt_notify

@doc """
```Julia
enable!(interrupt::XRT.XRTWrap.IPInterrupt)

```

Enables the IP interrupt if not already enabled.
""" enable!

@doc """
```Julia
disable!(interrupt::XRT.XRTWrap.IPInterrupt)

```

Disables the IP interrupt notification from IP.
""" disable!

@doc """
```Julia
wait(interrupt::XRT.XRTWrap.IPInterrupt)
wait(interrupt::XRT.XRTWrap.IPInterrupt, timeout::Integer) -> XRT.XRTWrap.CVStatus.Type

```

Wait for interrupt from IP or for the specified timeout to expire. 
""" wait