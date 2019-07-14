using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/b4gic.m"
net = PowerModels.parse_file(path)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

# result = run_gmd(net, solver; setting=branch_setting)

result = run_ac_gmd_opf(net, solver; setting=branch_setting)
# result = run_ac_gmd_opf(net, solver)

 




