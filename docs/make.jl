using Documenter
using DocThemePC2
using XRT

const ci = get(ENV, "CI", "") == "true"

@info "Preparing DocThemePC2"
DocThemePC2.install(@__DIR__)

@info "Generating Documenter.jl site"
makedocs(;
         sitename = "XRT.jl",
         authors = "Marius Meyer, Lukas Tobias Müller",
         modules = [XRT],
         checkdocs = :exports,
         # doctest = ci,
         pages = [
             "Home" => "index.md",
             "Manual" => [
                "Introduction" => "manual/introduction.md",
                "Installation" => "manual/installation.md",
                "Devices" => "manual/devices.md",
                "XCLBIN" => "manual/xclbin.md",
                "Kernels And IPs" => "manual/kernel.md",
                "Buffer Objects" => "manual/boarray.md" ,
                "High-Level Execution" => "manual/high_level.md",
                "Command-Line Tools" => "manual/tools.md",
                "Miscellaneous" => "manual/misc.md",
                "Testing" => "manual/testing.md",
                "Troubleshooting" => "manual/troubleshooting.md"
             ],
             "Examples" => [
                 "XRT API" => "examples/xrt_api.md",
                 "Automatic Buffer Synchronization" => "examples/synchronization.md",
                 "Auto-generate Kernel Interface" => "examples/high_level_basics.md",
                 "STREAM TRIAD Example" => "examples/stream.md"
             ],
             "References" => [
                 "XRT.jl Public API" => "refs/api.md",
                 "Configuration File xrt.ini" => "refs/ini.md",
                 "Module _XRTInternal" => "refs/internal.md"
             ],
             "issues.md"
         ],
         repo = "https://github.com/pc2/XRT.jl/blob/{commit}{path}#{line}",
         format = Documenter.HTML(; assets = ["assets/favicon.ico"]))

if ci
    @info "Deploying documentation to GitHub"
    deploydocs(;
               repo = "github.com/pc2/XRT.jl.git",
               devbranch = "main",
               push_preview = true
               # target = "site",
               )
end