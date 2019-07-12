using JSON, PowerModelsGMD, GZip

path = "data/tx2000.json"
#path = "data/b4gic.m"
#path = "data/epri21.m"

path = "data/eastern_fixed_pretty.json.gz"
path = "data/wecc_fixed.json.gz"
path = "data/rts-gmlc_fixed.json.gz"
path = "data/rts-gmlc.json.gz"

#path = "data/northeast-fixed.json"
#path = "data/northeast.json"
#path = "data/isone.json"
path = "data/ercot_7ddad08.json.gz"

if length(ARGS) >= 1
    path = ARGS[1]
end

println("Loading $path")
#net = PowerModels.parse_file(path)
h = GZip.open(path)
net = JSON.parse(h)
close(h)

hash = net["meta"]["hash"][1:7]

println("Source path: $(net["source_path"])")
println("Date stamp: $(net["meta"]["timestamp"])")
println("Hash: $hash")
    
nb = length(net["bus"])
println("Number of buses: $nb")

println("Solving $path")
##function run_gic_matrix(net)
# We will be solving for bus to ground currents.  We have two matrices to 
# worry about, Y and Z.  Both are nxn where n is the number of busses.  Y
# is symetric and, for now, Z is diagonal.

result = run_gic_matrix(net)
net["result"] = result

# take the average gmd bus voltage
va = mean([a["gmd_vdc"] for (k,a) in result["solution"]["gmd_bus"]])
println("Average gmd bus voltage: $va")

opath = replace(path, ".json", "_results.json")
#opath = replace(opath, ".m", "_results.json")
println("Writing $opath")
h = GZip.open(opath, "w")
JSON.print(h, net)
close(h)

opath2 = replace(path, ".json", "_$(hash)_results.json")
println("Writing $opath2")
h = GZip.open(opath2, "w")
JSON.print(h, net)
close(h)
println("Done")
