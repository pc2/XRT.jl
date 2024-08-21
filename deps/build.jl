using CxxWrap
using Pkg
using Scratch
using xrt_jll
using Logging
using Libuuid_jll

uuid = Base.UUID(Pkg.TOML.parsefile("../Project.toml")["uuid"])
#@show keys(Pkg.TOML.parsefile(joinpath(dirname(@__DIR__), "../Project.toml")))
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
    # xbutil_version = get_version(read(`$(xrt_jll.artifact_dir)/bin/xbutil --version`, String))
end

mkdir(build_dir())
cd(build_dir())
run(`cmake ../xrt_cxxwrap $cmake_opts -DCMAKE_PREFIX_PATH=$(CxxWrap.prefix_path())`)
run(`make xrtwrap`)
mv("libxrtwrap.so", joinpath(get_scratch!(uuid, "lib"), "libxrtwrap.so"), force=true)


