using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP

println("Start loading json")
path = "../gmd-tools/data/epri21.json"
#path = "../gmd-tools/data/b4gic.json"
path = "../gmd-tools/data/sc500.json"
path = "../gmd-tools/data/eastern.json"
path = "data/northeast_fixed.json.tgz"
path = "data/isone.json.tgz"
path = "data/b4gic.m"
path = "data/rts-gmlc_fixed.json.gz"
path = "data/rts-gmlc-gic.json.gz"
path = "data/epri21.m"
#path = "data/rts-gmlc.json.gz"
path = "data/rts-gmlc-gic.json"
opath = "data/rts-gmlc-gic-results.json"
#path = "../gmd-tools/data/tx2000.json.gz"
#path = "../gmd-tools/data/uiuc150.json.gz"

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


 




