using GZip, JSON, Ipopt, PowerModelsGMD

println("Start loading json")
path = "../gmd-tools/data/epri21.json"
#path = "../gmd-tools/data/b4gic.json"
path = "../gmd-tools/data/sc500.json"
path = "../gmd-tools/data/eastern.json"
#path = "../gmd-tools/data/tx2000.json"
path = "data/northeast_fixed.json.tgz"
path = "data/isone.json.tgz"
path = "data/b4gic.m"
path = "data/epri21.m"

println("Start loading $path")
net = PowerModels.parse_file(path)
#h = open(path)
#net = JSON.parse(h)
#close(h)
println("Done loading $path")


ipopt_solver = IpoptSolver()
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
println("Start solving")
result = run_gic(net, ipopt_solver; setting=setting)
println("Done solving")

opath = replace(path,".json","_results.json")
opath = replace(path, ".m", "_results.json")
h = GZip.open(opath,"w")
JSON.print(h, result)
close(h)


 




