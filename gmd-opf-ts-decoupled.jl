using PowerModels, PowerModelsGMD, Ipopt, JSON, JuMP, CSV, DataFrames
# -- T E S T I N G -- #

println("")

# Load waveform data
println("Load waveform data\n")
wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
mods = JSON.parse(h)
close(h)

mods["waveforms"] = nothing

# Load case data
println("Load case data\n")
path = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/b4gic.m")
net = PowerModels.parse_file(path)
net["name"] = "B4GIC"
base_mva = net["baseMVA"]
println("")




# Running model
println("Running model: $(net["name"]) \n")
solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true, "transformer_temperatures" => true))

results = PowerModelsGMD.run_ac_gmd_opf_ts_decoupled(net, solver, mods, setting)

# plot the transformer heating results
# julia> results[1]["temperatures"]
# Dict{String,Array{Any,1}} with 5 entries:
#   "branch"               => Any["1", "3"]
#   "delta_topoilrise_ss"  => Any[0.99509, 1.08058]
#   "delta_hotspotrise_ss" => Any[23.5132, 23.5132]
#   "Ieff"                 => Any[37.3225, 37.3225]
#   "actual_hotspot"       => Any[49.5082, 49.5937]

# t = mods["time"]
# do1 = [x["temperatures"]["delta_topoilrise_ss"][1] for x in results]
# do2 = [x["temperatures"]["delta_topoilrise_ss"][2] for x in results]
# plot(t, do1)
# plot!(t, do2)

output = Dict()
output["case"] = net
output["result"] = results


# Save results to output
outfile = string("data/", net["name"], "_gmd_opf_ts_decoupled.json")
println("\nSaving results to $outfile")
f = open(outfile,"w")
JSON.print(f, output)
close(f)


