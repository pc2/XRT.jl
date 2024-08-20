using CxxWrap
using Pkg
using Scratch
using xrt_jll
using Logging

uuid = Base.UUID(Pkg.TOML.parsefile("../Project.toml")["uuid"])
#@show keys(Pkg.TOML.parsefile(joinpath(dirname(@__DIR__), "../Project.toml")))
build_dir() = "build_xrt_cxxwrap"

if isdir(build_dir())
    rm(build_dir(), force=true, recursive=true)
end

cmake_opts = ""
if "XILINX_XRT" in keys(ENV)
    @info "Build using native XRT at $(ENV["XILINX_XRT"])"
    cmake_opts = "-DXILINX_XRT=$(ENV["XILINX_XRT"])"
else
    @info "Build using xrt_jll"
    cmake_opts = "-DXILINX_XRT=$(xrt_jll.artifact_dir)"
end

mkdir(build_dir())
cd(build_dir())
run(`cmake ../xrt_cxxwrap $cmake_opts -DCMAKE_PREFIX_PATH=$(CxxWrap.prefix_path())`)
run(`make xrtwrap`)
mv("libxrtwrap.so", joinpath(get_scratch!(uuid, "lib"), "libxrtwrap.so"), force=true)


