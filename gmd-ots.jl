using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP, Debugger, Juniper, Cbc

#path = "data/b4gic.m"
path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/ots_test.m"
net = PowerModels.parse_file(path)

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=ipopt_solver, mip_solver=cbc_solver, log_levels=[])

branch_setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
result = run_ac_gmd_ots(path, juniper_solver)

 




