using CxxWrap
using Pkg
using Scratch
using xrt_jll
using Logging
using Libuuid_jll
using CMake

uuid = Base.UUID(Pkg.TOML.parsefile("../Project.toml")["uuid"])
build_dir() = "build_xrt_cxxwrap"

if isdir(build_dir())
    rm(build_dir(), force=true, recursive=true)
end

get_version(xbutil_version) = VersionNumber(match(r"Version\s+:\s+(\d+\.\d+\.\d+)", xbutil_version)[1])

xbutil_version = VersionNumber("1")

@info "Use Libuuid in $(Libuuid_jll.artifact_dir)"
cmake_opts = ["-DLIB_UUID_DIR=$(Libuuid_jll.artifact_dir)"]
if "XILINX_XRT" in keys(ENV)
    @info "Build using native XRT at $(ENV["XILINX_XRT"])"
    push!(cmake_opts,"-DXILINX_XRT=$(ENV["XILINX_XRT"])")
    # xbutil_version = get_version(read(`xbutil --version`, String))
else
    @info "Build using xrt_jll"
    push!(cmake_opts, "-DXILINX_XRT=$(xrt_jll.artifact_dir)")
    ENV["XILINX_XRT"] = xrt_jll.artifact_dir 
    # xbutil_version = get_version(read(`$(xrt_jll.artifact_dir)/bin/xbutil --version`, String))
end

push!(cmake_opts, "-DCMAKE_INSTALL_PREFIX=$(get_scratch!(uuid, "xrtwrap"))")

mkdir(build_dir())
run(`$(CMake.cmake) -S xrt_cxxwrap -B $(build_dir()) $cmake_opts -DCMAKE_PREFIX_PATH=$(CxxWrap.prefix_path())`)
run(`$(CMake.cmake) --build $(build_dir())`)
run(`$(CMake.cmake) --install $(build_dir())`)
