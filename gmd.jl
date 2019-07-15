using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP, DelimitedFiles
include("powermodelsio.jl")

println("Start loading json")
path = "data/rts-gmlc-gic.json"
opath = "data/rts-gmlc-gic-results.json"



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

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
println("Start solving")
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
result = run_gmd(net, ipopt_solver; setting=setting)

io = open("data/rts_gmlc_gic.m", "w")
PowerModels.export_matpower(io, net)
close(io)