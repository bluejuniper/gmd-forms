using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

path = "data/tx2000.json"
path = "data/b4gic.m"

path = "data/eastern.json"
opath = "data/eastern-fixed.json"

path = "data/northeast.json"
opath = "data/northeast-fixed.json"
#path = "data/isone.json"

println("Start loading $path")
#net = PowerModels.parse_file(path)
h = open(path)
net = JSON.parse(h)
close(h)
println("Done loading $path")

println("Start fixing resistances")
for (k,b) in net["gmd_bus"]
    if b["g_gnd"] == 0.0
        println("Fixing bus $k")
        b["g_gnd"] = 1e-6
    end
end

for (k,b) in net["gmd_branch"]
    if b["br_r"] == 0.0
        println("Fixing branch $k")
        b["br_r"] = 1e-6
    end
end
println("Done fixing resistances")

println("Start writing $opath")
h = open(opath, "w")
JSON.print(h, net)
close(h)
println("Done writing $opath")
