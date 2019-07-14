using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/uiuc150.m"
net = PowerModels.parse_file(path)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

# result = run_gmd(net, solver; setting=branch_setting)
# result = run_ac_opf(net, solver; setting=branch_setting)
# result = run_ac_gmd_opf(net, solver; setting=branch_setting)

for (k,x) in net["load"]
    x["pd"] *= 0.95
    x["qd"] *= 0.95
end

output = run_ac_gmd_opf_decoupled(net, solver; setting=branch_setting)
output["ac"]["result"]

# result = run_ac_gmd_opf(net, solver; setting=branch_setting)
# result = run_ac_gmd_opf(net, solver)

 




