using GZip, JSON, Ipopt, PowerModels, PowerModelsGMD

println("Start loading json")
path = "../gmd-tools/data/epri21.json"
#path = "../gmd-tools/data/b4gic.json"
path = "../gmd-tools/data/sc500.json"
path = "../gmd-tools/data/eastern.json"
path = "data/northeast_fixed.json.tgz"
path = "data/isone.json.tgz"
path = "data/b4gic.m"
path = "data/epri21.m"
#path = "data/rts-gmlc_fixed.json.gz"
path = "data/rts-gmlc-geo.json.gz"
path = "data/rts-gmlc-gic.json.gz"
#path = "data/RTS_GMLC_Geo.m"
#path = "data/rts-gmlc.json"
#path = "../gmd-tools/data/tx2000.json.gz"
#path = "../gmd-tools/data/uiuc150.json.gz"
path = "data/rts_gmlc_gic.m"

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


solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
s = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
println("Start solving")
#result = run_gic(net, ipopt_solver; setting=setting)
result = run_ac_gmd_opf_decoupled(net, solver; setting=s)
#result = run_ac_opf(net, ipopt_solver; setting=setting)
#result = PowerModelsLANL.run_ml(net, SOCWRPowerModel, ipopt_solver)
println("Done solving")

ipath = replace(path,".json","_gic_opf_decoupled.json")
ipath = replace(ipath, ".m", "_gic_opf_decoupled.json")
h = GZip.open(ipath,"w")
JSON.print(h, net)
close(h)



opath = replace(path,".json","_gic_opf_decoupled_results.json")
opath = replace(opath, ".m", "_gic_opf_decoupled_results.json")
h = GZip.open(opath,"w")
JSON.print(h, result)
close(h)


 




