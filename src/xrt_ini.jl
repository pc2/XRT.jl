using .XRTWrap: set!
using .XRTWrap: log

@doc """
```Julia
log(level::XRT.XRTWrap.LogLevel.Type, tag::AbstractString, msg::AbstractString)

```

This function dispatches a composed log message.
The message is ignored if the configured verbosity level is less than specified level.
""" log

"""
$(TYPEDSIGNATURES)

This function composes a formatted string using args (similar to `printf` function) and dispatches this log:

```Julia
julia> XRT.logf(XRT.LogLevel.WARNING, "myTag", "This is a %1 %2", "log", "message")

```
"""
function logf(level::XRT.LogLevel.Type, tag::AbstractString, format::AbstractString, args...)
	formatted_str = format
	for (i, arg) in enumerate(args)
		placeholder = "%" * string(i)
		formatted_str = replace(formatted_str, placeholder => string(arg))
	end
	log(level, tag, formatted_str)
end

module XRTConfiguration

# Runtime Group
"""
Enable or disable OpenCL API checks.

Default: true

        [true|false]
"""
const API_CHECKS = "Runtime.api_checks"

"""
Specify where the runtime logs are printed.

Default: console

        [null|console|syslog|filename]
"""
const RUNTIME_LOG = "Runtime.runtime_log"

"""
Pin all runtime threads to specified CPUs.

Example: cpu_affinity = {4,5,6}

        [{N,N,…}]
"""
const CPU_AFFINITY = "Runtime.cpu_affinity"

"""
Verbosity level of log messages. Higher number implies more verbosity.

Default: 4

        [0|1|2|3|4|5|6|7]
"""
const VERBOSITY = "Runtime.verbosity"

"""
When setting true OpenCL process holds exclusive access of the Compute Units.

Default: false

        [false|true]
"""
const EXCLUSIVE_CU_CONTEXT = "Runtime.exclusive_cu_context"

# Debug Group
"""
Enable or disable OpenCL host code profile. Set true to generate profile_summary report.

Default: false

        [true|false]
"""
const PROFILE = "Debug.profile"

"""
Enable or disable profile timeline trace. Set true to generate timeline_trace report.

Default: false

        [true|false]
"""
const TIMELINE_TRACE = "Debug.timeline_trace"

"""
Enable device-level AXI transfers trace.

Default: off

        [coarse|fine|off]
"""
const DATA_TRANSFER_TRACE = "Debug.data_transfer_trace"

"""
Specifies type of stalls to be captured in timeline trace report.

Default: off

        [dataflow|memory|pipe|all|off]
"""
const STALL_TRACE = "Debug.stall_trace"

"""
If true, enable xprint and xstatus command during debugging with xgdb.

Default: false

        [true|false]
"""
const APP_DEBUG = "Debug.app_debug"

"""
Specifies the size of DDR/HBM memory for storing trace data. This option only applicable in hardware flow. If no unit is given byte is assumed.

Default: 1M

        [N {K|M|G}]
"""
const TRACE_BUFFER_SIZE = "Debug.trace_buffer_size"

"""
Enables or disables low overhead profiling.

Default: false

        [false|true]
"""
const LOP_TRACE = "Debug.lop_trace"

"""
Enables the continuous offload of the device data while the application is running. In the event of a crash/hang a trace file will be available to help debugging.

Default: false

        [false|true]
"""
const CONTINUOUS_TRACE = "Debug.continuous_trace"

"""
Specifies the interval in millisecond to offload the device data in continous trace mode.

Default: 10

        [N]
"""
const CONTINUOUS_TRACE_INTERVAL_MS = "Debug.continuous_trace_interval_ms"

# Emulation Group
"""
Specify the interval in seconds that aliveness messages need to be printed.

Default: 300

        [N]
"""
const ALIVENESS_MESSAGE_INTERVAL = "Emulation.aliveness_message_interval"

"""
Controls the printing of emulation info messages to users console. Emulation info messages are always logged into a file called emulation_debug.log

Default: true

        [true|false]
"""
const PRINT_INFOS_IN_CONSOLE = "Emulation.print_infos_in_console"

"""
Controls the printing of emulation warning messages to users console. Emulation warning messages are always logged into a file called emulation_debug.log

Default: true

        [true|false]
"""
const PRINT_WARNING_IN_CONSOLE = "Emulation.print_warning_in_console"

"""
Controls the printing of emulation error messages to users console. Emulation error messages are always logged into a file called emulation_debug.log

Default: true

        [true|false]
"""
const PRINT_ERRORS_IN_CONSOLE = "Emulation.print_errors_in_console"

"""
Specify how the waveform is saved and displayed during emulation. The kernel needs to be compiled with debug enabled for the waveform to be saved and displayed in the simulator GUI.

Default: off

        [off|batch|gui]
"""
const LAUNCH_WAVEFORM = "Emulation.launch_waveform"

"""
Specify the time scaling unit of timeout specified clPollStreams command, otherwise Emulation does not support timeout specified in clPollStreams command.

Default: na (not applicable)

        [na|ms|sec|min]
"""
const TIMEOUT_SCALE = "Emulation.timeout_scale"

end # XRTConfiguration

@doc """
```Julia
set!(key::AbstractString, value::AbstractString)
set!(key::AbstractString, value::Integer)

```

Change xrt.ini string value for specified key.
Possible keys can be found in `XRT.XRTConfiguration` module.
See [Configuration File xrt.ini](@ref) section of docs for mor information.
""" set!