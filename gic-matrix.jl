using JSON, PowerModelsGMD

path = "data/tx2000.json"
path = "data/b4gic.m"
path = "data/epri21.m"

#path = "data/eastern-fixed.json"
#path = "data/northeast-fixed.json"
#path = "data/northeast.json"
#path = "data/isone.json"

println("Start loading $path")
net = PowerModels.parse_file(path)
#h = open(path)
#net = JSON.parse(h)
#close(h)
println("Done loading $path")

println("Start solving $path")
##function run_gic_matrix(net)
# We will be solving for bus to ground currents.  We have two matrices to 
# worry about, Y and Z.  Both are nxn where n is the number of busses.  Y
# is symetric and, for now, Z is diagonal.

nbus = length(net["gmd_bus"])
busids = Dict([(b["index"], i) for (i, b) in enumerate(values(net["gmd_bus"]))])
buskeys = collect(keys(net["gmd_bus"]))

# First we need JJ, which is the perfect earth grounding current at each
# bus location.  It is the sum of the emf on each line going into a
# substation time the y for that line

J = zeros(nbus)

iy = Array(1:nbus) #  diag rows
jy = Array(1:nbus) #  diag cols
vy = zeros(nbus) #  diagonal values

# create the on-diagonal values of Y
for (k, branch) in net["gmd_branch"]
    m = busids[branch["f_bus"]]
    n = busids[branch["t_bus"]]

    if m == n || branch["br_status"] != 1
        continue
    end

    J[m] -= branch["br_v"]/branch["br_r"]
    J[n] += branch["br_v"]/branch["br_r"]
    
    # YY
    vy[m] += 1/branch["br_r"]
    vy[n] += 1/branch["br_r"]
end

# create the off-diagonal values of Y
for (k, branch) in net["gmd_branch"]
    m = busids[branch["f_bus"]]
    n = busids[branch["t_bus"]]

    if m == n || branch["br_status"] != 1
        continue
    end

    # matVals
    push!(iy, m)
    push!(jy, n)
    push!(vy, -1/branch["br_r"])

    push!(iy, n)
    push!(jy, m)
    push!(vy, 1/branch["br_r"])
end

Y = sparse(iy, jy, vy)

iz = Array(1:nbus)
jz = Array(1:nbus)
vz = [1/max(b["g_gnd"], 1e-6) for (k,b) in net["gmd_bus"]]
Z = sparse(iz, jz, vz)

I = speye(nbus)
MM = Y*Z
M = I + MM

#return M\J # GIC flowing into each bus grounding resistance
gic = M\J # GIC flowing into each bus grounding resistance
vdc = Z*gic
result = Dict()
result["gic"] = Dict()
result["vdc"] = Dict()
##end

for (i,v) in enumerate(vdc)
    k = buskeys[i]
    result["vdc"]["$k"] = v
    result["gic"]["$k"] = gic[i]
end

println("Done solving $path")

opath = replace(path, ".json", "_results.json")
opath = replace(path, ".m", "_results.json")
println("Start writing $opath")
h = open(opath, "w")
JSON.print(h, result)
close(h)
println("Done writing $opath")
