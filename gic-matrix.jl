using JSON, PowerModelsGMD

function run_gic_matrix(net)
    # We will be solving for bus to ground currents.  We have two matrices to 
    # worry about, Y and Z.  Both are nxn where n is the number of busses.  Y
    # is symettric and, for now, Z is diagonal.

    num_branches = length(net["gmd_branch"])
    num_buses = length(net["gmd_bus"])
    bus_ids = Dict([(b["index"], i) for (i, b) in enumerate(values(net["gmd_bus"]))])

    # First we need JJ, which is the perfect earth grounding current at each
    # bus location.  It is the sum of the emf on each line going into a
    # substation time the y for that line

    J = zeros(num_buses)

    iy = Array(1:num_buses) #  diag rows
    jy = Array(1:num_buses) #  diag cols
    vy = zeros(num_buses) #  diagonal values

    # create the on-diagonal values of Y
    for (k, branch) in net["gmd_branch"]
        m = bus_ids[branch["f_bus"]]
        n = bus_ids[branch["t_bus"]]

        if m == n || branch["br_status"] != 1
            continue
        end

        J[m] -= branch["br_v"]/branch["br_r"]
        J[n] += branch["br_v"]/branch["br_r"]
        
        vy[m] += 1/branch["br_r"]
        vy[n] += 1/branch["br_r"]
    end

    # create the off-diagonal values of Y
    for (k, branch) in net["gmd_branch"]
        m = bus_ids[branch["f_bus"]]
        n = bus_ids[branch["t_bus"]]

        if m == n || branch["br_status"] != 1
            continue
        end

        push!(iy, m)
        push!(jy, n)
        push!(vy, -1/branch["br_r"])

        push!(iy, n)
        push!(jy, m)
        push!(vy, 1/branch["br_r"])
    end


    Y = sparse(iy, jy, vy)

    zmm = zeros(num_buses)
    znn = zeros(num_buses)
    zmatVals = zeros(num_buses)

    iz = Array(1:num_buses)
    jz = Array(1:num_buses)
    vz = [1/b["g_gnd"] for (k,b) in net["gmd_bus"]]

    Z = sparse(iz, jz, vz)
    I = speye(num_buses, num_buses)
    MM = Y*Z
    M = I + MM

    return M\J # GIC flowing into each bus grounding resistance
end

path = "data/tx2000.json"
path = "data/b4gic.m"

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
result = run_gic_matrix(net)
println("Done solving $path")

opath = replace(path, ".json", "_results.json")
println("Start writing $opath")
h = open(opath, "w")
JSON.print(h, result)
close(h)
println("Done writing $opath")
