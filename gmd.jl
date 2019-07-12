using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP, DelimitedFiles
include("powermodelsio.jl")

println("Start loading json")
path = "data/rts-gmlc-gic.json"
# path = "data/rts-gmlc-gic.raw"
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
    println("Converting to per-unit")
end
println("Done loading $path")

net["storage"] = Dict()

# for (k,x) in net["gen"]
#     i = x["gen_bus"]
#     net["bus"]["$i"]["bus_type"] = 2
# end

# for (k,x) in net["branch"]
#     x["g_fr"] = 0.0
#     x["g_to"] = 0.0
#     x["b_fr"] = x["br_b"]/2
#     x["b_to"] = x["br_b"]/2
# end



# net["per_unit"] = false
PowerModels.make_per_unit!(net)
#for (k,x) = net["gmd_bus"]
#    x["status"] = 1
#end

# pm = PowerModels.build_model(net, PowerModelsGMD.ACPPowerModel, PowerModelsGMD.post_gmd)

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
println("Start solving")
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
#result = run_gmd(net, ipopt_solver; setting=setting)
# result = run_ac_gmd_pf_decoupled(net, ipopt_solver; setting=setting)
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

# result = run_dc_opf(net, ipopt_solver; setting=setting)
# result = run_ac_opf(net, ipopt_solver; setting=setting)
# result = run_ac_pf(net, ipopt_solver; setting=setting)
# println("Done solving")
# result


#opath = replace(path,".json","_results.json")
#opath = replace(opath, ".m", "_results.json")
#h = GZip.open(opath,"w")
h = open(opath,"w")
JSON.print(h, result)
close(h)


gbus_df = to_df(net, "gmd_bus", solution=dc_result["solution"])
gb=gbus_df[gbus_df[:parent_type].=="bus",:]
sort!(gb,[:parent_index])

bus_df = to_df(net, "bus", solution=ac_result["solution"])
sort!(bus_df,[:index])

branch_df = to_df(net, "branch", solution=ac_result["solution"])
sort!(branch_df,[:f_bus,:t_bus,:ckt])

dc_branch_df = to_df(net, "branch", solution=dc_result["solution"])
sort!(dc_branch_df,[:f_bus,:t_bus,:ckt])

branch_df = to_df(net, "branch", solution=ac_result["solution"])
sort!(branch_df,[:f_bus,:t_bus,:ckt])


# save the branch results
io = open("data/rts-gmlc-gic-gbus.csv", "w")
write(io, join(names(gb), ",") * "\n")
writedlm(io, eachrow(gb), ",")
close(io)

# save the branch results
cols = [:f_bus,:t_bus,:ckt,:type,:gmd_qloss,:pf,:qf,:pt,:qt,:gmd_vdc,:len_km]
io = open("data/rts-gmlc-gic-branch.csv", "w")
write(io, join(cols, ",") * "\n")
writedlm(io, eachrow(branch_df[cols]), ",")
close(io)