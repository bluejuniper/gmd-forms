using PowerModels, PowerModelsGMD, Ipopt, JuMP, JSON


# Load waveform data
println("Load waveform data\n")
wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
wf_data = JSON.parse(h)
close(h)

timesteps = wf_data["time"]
n = length(timesteps)
t = range(0, stop=(3600*3*3), length=n)
Delta_t = t[2]-t[1]
waveforms = wf_data["waveforms"]


# Load case data
println("Load case data\n")
path = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/b4gic.m")
raw_net = PowerModels.parse_file(path)
raw_net["name"] = "B4GIC"
base_mva = raw_net["baseMVA"]
println("")


# Running model
println("Running model: $(raw_net["name"]) \n")
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

results = []

# Create replicates (multiples) of the network
net = PowerModels.replicate(raw_net,n)


# Update values in each replicates
for repl in keys(net["nw"])

    for i in 1:n
        #println("########## Time: $(t[i]) ########## \n")

        #update the vs values
        for (k,wf) in waveforms
            otype = wf["parent_type"]
            field  = wf["parent_field"]
            net["nw"][repl][otype][k][field] = wf["values"][i]
        end        

    end

end

result = run_gmd_opf_ts(net, PowerModelsGMD.ACPPowerModel, ipopt_solver, setting=setting)



