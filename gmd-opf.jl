using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

#path = "data/b4gic.m"
path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/b4gic.m"
net = PowerModels.parse_file(path)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
branch_setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
#result = run_ac_gmd_opf(net, solver; setting=branch_setting)
result = run_ac_gmd_opf(net, solver)

 




