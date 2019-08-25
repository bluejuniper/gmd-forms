using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP, Printf

include("powermodelsio.jl")
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/uiuc150_95pct_loading.m"
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/epri21_ots.m"

net = PowerModels.parse_file(path)
update_gmd_status!(net)
solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
result = run_ac_gmd_opf(net, solver; setting=branch_setting)




