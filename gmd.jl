using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP

println("Start loading json")
path = "data/rts-gmlc-gic.json"
opath = "data/rts-gmlc-gic-results.json"

path = "data/b4gic.json"
opath = "data/b4gic-results.json"

path = "data/epri21.json"
opath = "data/epri21-results.json"

path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/b4gic.m"
opath = "data/b4gic-results.json"

path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/b6gic_nerc.m"
opath = "data/b6gic-nerc-results.json"

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

#for (k,x) = net["gmd_bus"]
#    x["status"] = 1
#end

pm = PowerModels.build_model(net, PowerModelsGMD.ACPPowerModel, PowerModelsGMD.post_gmd)

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
println("Start solving")
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
result = run_gmd(net, ipopt_solver; setting=setting)
println("Done solving")

#opath = replace(path,".json","_results.json")
#opath = replace(opath, ".m", "_results.json")
#h = GZip.open(opath,"w")
h = open(opath,"w")
JSON.print(h, result)
close(h)


 




