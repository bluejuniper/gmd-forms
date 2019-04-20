using GZip, JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

if length(ARGS) >= 1
    path = ARGS[1]
else
    #path = "data/eastern.json"
    path = "data/wecc.json.gz"
end

opath = replace(path, ".json", "_fixed.json")


println("Start loading $path")
#net = PowerModels.parse_file(path)
#h = open(path)
h = GZip.open(path)
net = JSON.parse(h)
close(h)
println("Done loading $path")

println("Start fixing resistances")
#for (k,b) in net["gmd_bus"]
#    if b["g_gnd"] == 0.0
#        println("Fixing bus $k")
#        b["g_gnd"] = 1e-6
#    end
#end

for (k,b) in net["gmd_branch"]
    if b["br_r"] == 0.0
        println("Fixing branch $k")
        b["br_r"] = 1e-6
    end
end
println("Done fixing resistances")

println("Start writing $opath")
#h = open(opath, "w")
h = GZip.open(opath, "w")
JSON.print(h, net)
close(h)
println("Done writing $opath")
