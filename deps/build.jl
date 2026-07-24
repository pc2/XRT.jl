module _XRTMake

using CxxWrap
using Pkg
using Scratch
using Logging
using Libuuid_jll
using CMake
using boost_jll
import Preferences

get_version(version_output) = VersionNumber(match(r"Version\s+:\s+(\d+\.\d+\.\d+)", version_output)[1])
get_xrtjl_root() = abspath(joinpath(Base.find_package("XRT"), "../../"))

uuid = Base.UUID(Pkg.TOML.parsefile(joinpath(get_xrtjl_root(), "Project.toml"))["uuid"])        
build_dir() = joinpath(get_xrtjl_root(), "deps", "build_xrt_cxxwrap")
source_dir() = joinpath(get_xrtjl_root(), "deps", "xrt_cxxwrap")

# XRT 2.19 renamed `xbutil` to `xrt-smi`.
function xrt_version(xrt)
    for tool in ("xrt-smi", "xbutil")
        path = joinpath(xrt, "bin", tool)
        isfile(path) || (path = something(Sys.which(tool), ""))
        isempty(path) || return get_version(read(`$(path) --version`, String))
    end
    error("Neither xrt-smi nor xbutil found in $(joinpath(xrt, "bin")) or on PATH")
end

# Only a native XRT needs a locally built shim; xrt_cxxwrap_jll ships one for xrt_jll.
# Keep this in step with XRTWrap.selected_xrt.
native_xrt = Preferences.load_preference(uuid, "xrt_path", get(ENV, "XILINX_XRT", ""))
if isempty(native_xrt) || any(depot -> occursin(depot, native_xrt), DEPOT_PATH)
    @info "XILINX_XRT does not point at a native XRT installation; using xrt_cxxwrap_jll"
else
    isdir(build_dir()) && rm(build_dir(), force=true, recursive=true)

    @info "Build using native XRT at $(native_xrt)"
    version = xrt_version(native_xrt)
    cmake_opts = ["-DXILINX_XRT=$(native_xrt)",
                  "-DLIB_UUID_DIR=$(Libuuid_jll.artifact_dir)",
                  "-DLIB_BOOST_DIR=$(boost_jll.artifact_dir)",
                  "-DCMAKE_INSTALL_PREFIX=$(get_scratch!(uuid, "xrtwrap"))",
                  "-DXRT_VERSION_NUMBER=$(version.major).$(version.minor)"]

    mkdir(build_dir())
    run(`$(CMake.cmake) -S $(source_dir()) -B $(build_dir()) $cmake_opts -DCMAKE_PREFIX_PATH=$(CxxWrap.prefix_path())`)
    run(`$(CMake.cmake) --build $(build_dir())`)
    run(`$(CMake.cmake) --install $(build_dir())`)
end

end
