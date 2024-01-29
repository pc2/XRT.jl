using CxxWrap
using Pkg
using Scratch

uuid = Base.UUID(Pkg.TOML.parsefile("../Project.toml")["uuid"])
#@show keys(Pkg.TOML.parsefile(joinpath(dirname(@__DIR__), "../Project.toml")))
build_dir() = "build_xrt_cxxwrap"

if isdir(build_dir())
    rm(build_dir(), force=true, recursive=true)
end

mkdir(build_dir())
cd(build_dir())
run(`cmake ../xrt_cxxwrap -DCMAKE_PREFIX_PATH=$(CxxWrap.prefix_path())`)
run(`make xrtwrap`)
mv("libxrtwrap.so", joinpath(get_scratch!(uuid,"lib"), "libxrtwrap.so"), force=true)


