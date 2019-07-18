using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP, DelimitedFiles
include("powermodelsio.jl")

println("Start loading json")
path = "data/rts_gmlc_gic.m"
path = "data/rts_gmlc_gic_new.m"

if length(ARGS) >= 1
    path = ARGS[1]
end

println("Start loading $path")
if endswith(path, ".m") || endswith(path, ".raw")
    net = PowerModels.parse_file(path)
elseif endswith(path, ".gz")
    h = GZip.open(path)
    net = JSON.parse(h)
    close(h)
elseif endswith(path, ".json")
    h = open(path)
    net = JSON.parse(h)
    close(h)
    println("Converting to per-unit")
end
println("Done loading $path")

net["storage"] = Dict()
PowerModels.make_per_unit!(net)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
s = Dict{String,Any}("output" => Dict{String,Any}("line_flows" => true))
println("Start solving")

result = run_ac_opf(net, solver; setting=s)

# opath = replace(ipath, ".m" => "_opf.json")
# h = GZip.open(opath, "w")
# JSON.print(h, result)
# close(h)






 




