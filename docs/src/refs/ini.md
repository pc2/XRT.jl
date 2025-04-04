# Configuration File xrt.ini

The following reference shows a list of all available configuration parameter.
Each parameter can be set using:

```@autodocs
Modules = [XRT]
Pages   = ["xrt_ini.jl"]
Filter  = func -> string(func) == "set!"
```

## Available configuration parameters

**Note: The keys and valid values are based on XRT 2.11 or Vitis 21.1. In newer versions, these may no longer be up-to-date. It is always possible to enter your own keys.**

### Runtime Group

```@autodocs
Modules = [XRT.XRTConfiguration]
Pages   = ["xrt_ini.jl"]
Filter = key -> startswith(key, "Runtime.")
```

### Debug Group

```@autodocs
Modules = [XRT.XRTConfiguration]
Pages   = ["xrt_ini.jl"]
Filter = key -> startswith(key, "Debug.")
```

### Emulation Group

```@autodocs
Modules = [XRT.XRTConfiguration]
Pages   = ["xrt_ini.jl"]
Filter = key -> startswith(key, "Emulation.")
```
