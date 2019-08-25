using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP, DelimitedFiles
include("powermodelsio.jl")


path = "data/rts_gmlc_gic.m"
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/epri21_ots.m"

PowerModels.make_per_unit!(net)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
s = Dict{String,Any}("output" => Dict{String,Any}("line_flows" => true))
println("Start solving")

output = run_ac_gmd_opf_decoupled(net, solver; setting=s)

ipath = replace(path,".json" => "_gic_opf_decoupled.json")
ipath = replace(ipath, ".m" => "_gic_opf_decoupled.json")
h = GZip.open(ipath,"w")
JSON.print(h, net)
close(h)



opath = replace(path,".json" => "_gic_opf_decoupled_results.json")
opath = replace(opath, ".m" => "_gic_opf_decoupled_results.json")
h = GZip.open(opath,"w")
JSON.print(h, result)
close(h)


 




