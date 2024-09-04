using Documenter
using DocThemePC2
using XRT

const ci = get(ENV, "CI", "") == "true"

@info "Preparing DocThemePC2"
DocThemePC2.install(@__DIR__)

@info "Generating Documenter.jl site"
makedocs(;
         sitename = "XRT.jl",
         authors = "Marius Meyer",
         modules = [XRT],
         checkdocs = :exports,
         # doctest = ci,
         pages = [
             "XRT" => "index.md",
             "Examples" => [
                 "XRT API" => "examples/xrt_api.md",
                 "Auto-generate Kernel Interface" => "examples/high_level_basics.md",
                 "STREAM TRIAD Example" => "examples/stream.md",
             ],
             "References" => [
                 "API" => "refs/api.md",
             ],
         ],
         # assets = ["assets/custom.css", "assets/custom.js"]
         repo = "https://github.com/pc2/XRT.jl/blob/{commit}{path}#{line}",
         format = Documenter.HTML(; collapselevel = 1))

if ci
    @info "Deploying documentation to GitHub"
    deploydocs(;
               repo = "github.com/pc2/XRT.jl.git",
               devbranch = "main",
               push_preview = true
               # target = "site",
               )
end