using GZip, JSON, Ipopt, PowerModels, PowerModelsGMD, PowerModelsLANL

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

path2 = "data/rts-gmlc-geo.json.gz"
h = GZip.open(path2)
net2 = JSON.parse(h)
close(h)

gen2 = Dict()

for (k,g) in net2["gen"]
    gen2[g["gen_bus"]] = g
end

net["storage"] = Dict()

for (k,b) in net["branch"]
    b["g_fr"] = 0
    b["g_to"] = 0
    #b["b_fr"] = 0.0*b["br_b"]/2
    #b["b_to"] = 0.0*b["br_b"]/2
    b["b_fr"] = 0.0
    b["b_to"] = 0.0
    b["angmin"] *= pi/180
    b["angmax"] *= pi/180 

    b["rate_a"] *= 10

    if b["type"] == "xf"
        b["rate_a"] *= 10
    else
        b["rate_a"] *= 1.1
    end
end

for (k,g) in net["gen"]
    b = g["gen_bus"]
    g["pmax"] *= 2/100
    g["qmax"] *= 2/100
    g["pmin"] = 0.0
    g["qmin"] = -g["qmax"]
end

for (k,b) in net["bus"]
    b["vmax"] = 1.5
    b["vmin"] = 0.5
end

for (k,b) in net["load"]
    b["pd"] /= 100
    b["qd"] /= 100
end

PowerModels.propagate_topology_status(net)
PowerModels.select_largest_component(net)


ipopt_solver = IpoptSolver()
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
println("Start solving")
#result = run_gic(net, ipopt_solver; setting=setting)
result = run_ac_gic_opf_decoupled(net, ipopt_solver; setting=setting)
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


 




