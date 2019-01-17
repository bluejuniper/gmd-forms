using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

path = "data/b4gic.m"
net = PowerModels.parse_file(path)

ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
result = run_ac_gmd(net, ipopt_solver; setting=setting)

 




