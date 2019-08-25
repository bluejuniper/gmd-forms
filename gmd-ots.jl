using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP, Debugger, Juniper, Cbc
include("powermodelsio.jl")

#path = "data/b4gic.m"
path = "/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/ots_test.m"
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/epri21_ots.m"

net = PowerModels.parse_file(path)
pm = PowerModelsGMD.GenericGMDPowerModel(net, PowerModels.StandardACPForm)

update_gmd_status!(net)

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=ipopt_solver, mip_solver=cbc_solver, log_levels=[])

branch_setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
# result = run_ac_gmd_ots(path, juniper_solver)
result = run_ac_gmd_ots(net, juniper_solver)

PowerModels.make_mixed_units!(net)

output = Dict()
output["file"] = path
output["case"] = net
output["result"] = result

io = open("data/epri21_ots.json", "w")
JSON.print(io, output)
close(io)




