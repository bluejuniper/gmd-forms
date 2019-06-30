using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP
include("powermodelsio.jl")

println("Start loading json")
path = "data/rts-gmlc-gic.json"
opath = "data/rts-gmlc-gic-results.json"

#path = "data/b4gic.json"
#opath = "data/b4gic-results.json"
#
#path = "data/epri21.json"
#opath = "data/epri21-results.json"
#
#path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/b4gic.m"
#opath = "data/b4gic-results.json"
#
#path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/b6gic_nerc.m"
#opath = "data/b6gic-nerc-results.json"

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
end
println("Done loading $path")

net["storage"] = Dict()

for (k,x) in net["branch"]
    x["g_fr"] = 0.0
    x["g_to"] = 0.0
    x["b_fr"] = x["br_b"]/2
    x["b_to"] = x["br_b"]/2
end

#for (k,x) = net["gmd_bus"]
#    x["status"] = 1
#end

pm = PowerModels.build_model(net, PowerModelsGMD.ACPPowerModel, PowerModelsGMD.post_gmd)

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
println("Start solving")
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
#result = run_gmd(net, ipopt_solver; setting=setting)
result = run_ac_gmd_opf_decoupled(net, ipopt_solver; setting=setting)
ac_result = result["ac"]["result"]
dc_result = result["dc"]["result"]

for (k,g) in net["gen"]
    g["pmin"] = 0
    g["qmin"] = -g["pmax"]
    g["qmax"] = g["pmax"]
end

for (k,d) in net["load"]
    d["pd"] *= 0.5
    d["qd"] *= 0.5
end

result = run_dc_opf(net, ipopt_solver; setting=setting)
result = run_ac_opf(net, ipopt_solver; setting=setting)
println("Done solving")
result


#opath = replace(path,".json","_results.json")
#opath = replace(opath, ".m", "_results.json")
#h = GZip.open(opath,"w")
h = open(opath,"w")
JSON.print(h, result)
close(h)


gbus_df = to_df(net, "gmd_bus", solution=dc_result["solution"])
gb=gbus_df[gbus_df[:parent_type].=="bus",:]
#sort!(gb,[:parent_index])

bus_df = to_df(net, "bus", solution=ac_result["solution"])
branch_df = to_df(net, "branch", solution=ac_result["solution"])
#sort!(branch_df,[:f_bus,:t_bus,:ckt])

branch_df = to_df(net, "branch", solution=result["solution"])
sort!(branch_df,[:f_bus,:t_bus,:ckt])
#branch_df[[:f_bus,:t_bus,:ckt,:pf,:qf,:pt,:qt]]
