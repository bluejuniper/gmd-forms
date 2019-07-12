using PowerModels, PowerModelsGMD, Ipopt
using JSON, JuMP, CSV, DataFrames


# -- T E S T I N G -- #

println("")

# Load waveform data
println("Load waveform data\n")
wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
mods = JSON.parse(h)
close(h)


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

# Save results to output
outfile = string("data/", net["name"], "-time-ext-result.json")
println("\nSaving results to $outfile")
f = open(outfile,"w")
JSON.print(f,results)
close(f)


