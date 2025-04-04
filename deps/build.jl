module _XRTMake

using CxxWrap
using Pkg
using Scratch
using Logging
using Libuuid_jll
using CMake
using boost_jll

get_version(xbutil_version) = VersionNumber(match(r"Version\s+:\s+(\d+\.\d+\.\d+)", xbutil_version)[1])
get_xrtjl_root() = abspath(joinpath(Base.find_package("XRT"), "../../"))

uuid = Base.UUID(Pkg.TOML.parsefile(joinpath(get_xrtjl_root(), "Project.toml"))["uuid"])        
build_dir() = joinpath(get_xrtjl_root(), "deps", "build_xrt_cxxwrap")
source_dir() = joinpath(get_xrtjl_root(), "deps", "xrt_cxxwrap")

if isdir(build_dir())
    rm(build_dir(), force=true, recursive=true)
end

xbutil_version = VersionNumber("1")

@info "Use Libuuid in $(Libuuid_jll.artifact_dir)"
cmake_opts = ["-DLIB_UUID_DIR=$(Libuuid_jll.artifact_dir)"]

@info "Use boost in $(boost_jll.artifact_dir)"
push!(cmake_opts, "-DLIB_BOOST_DIR=$(boost_jll.artifact_dir)")

if haskey(ENV, "XILINX_XRT") && !any(path -> occursin(path, ENV["XILINX_XRT"]), DEPOT_PATH)
    @info "Build using native XRT at $(ENV["XILINX_XRT"])"
    push!(cmake_opts,"-DXILINX_XRT=$(ENV["XILINX_XRT"])")
    xbutil_version = get_version(read(`xbutil --version`, String))
else
    @info "Build using xrt_jll"
    using xrt_jll
    push!(cmake_opts, "-DXILINX_XRT=$(xrt_jll.artifact_dir)")
    ENV["XILINX_XRT"] = xrt_jll.artifact_dir 
    xbutil_version = get_version(read(`$(xrt_jll.xbutil()) --version`, String))
end

push!(cmake_opts, "-DCMAKE_INSTALL_PREFIX=$(get_scratch!(uuid, "xrtwrap"))")
push!(cmake_opts, "-DXRT_VERSION_NUMBER=$(xbutil_version.major).$(xbutil_version.minor)")

mkdir(build_dir())
run(`$(CMake.cmake) -S $(source_dir()) -B $(build_dir()) $cmake_opts -DCMAKE_PREFIX_PATH=$(CxxWrap.prefix_path())`)
run(`$(CMake.cmake) --build $(build_dir())`)
run(`$(CMake.cmake) --install $(build_dir())`)

end
