using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP, DelimitedFiles
include("powermodelsio.jl")

path = "data/rts_gmlc_gic.m"
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/ots_test.m"
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/epri21_ots.m"
net = PowerModels.parse_file(path)

net["storage"] = Dict()

# disable gmd circuit elements based on the ac circuit elements
update_gmd_status!(net)


PowerModels.make_per_unit!(net)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
s = Dict{String,Any}("output" => Dict{String,Any}("line_flows" => true))
println("Start solving")


pm = PowerModelsGMD.GenericGMDPowerModel(net, PowerModels.StandardACPForm)
result = run_gmd(net, solver; setting=s)

ipath = replace(path,".json" => "_gic.json")
ipath = replace(ipath, ".m" => "_gic.json")
h = GZip.open(ipath,"w")
JSON.print(h, net)
close(h)

opath = replace(path,".json" => "_gic_results.json")
opath = replace(opath, ".m" => "_gic_results.json")
h = GZip.open(opath,"w")
JSON.print(h, result)
close(h)


 




