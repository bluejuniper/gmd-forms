using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP, Printf

include("powermodelsio.jl")
path = "C:/Users/305232/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/uiuc150_95pct_loading.m"
net = PowerModels.parse_file(path)

solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))



# for (k,x) in net["load"]
#     x["pd"] *= 0.95
#     x["qd"] *= 0.95
# end

# for (k,x) in net["branch"]
#     x["rate_a"] *= 1.05
# end

# for (k,g) in net["gen"]
#     g["pmax"] /= 10
#     g["pmin"] /= 10
#     g["qmax"] /= 10
#     g["qmin"] /= 10
# end

# result = run_gmd(net, solver; setting=branch_setting)
# result = run_ac_opf(net, solver; setting=branch_setting)
result = run_ac_gmd_opf(net, solver; setting=branch_setting)
# output = run_ac_gmd_opf_decoupled(net, solver; setting=branch_setting)
# println(output["ac"]["result"])

# acgens = todf(output["ac"]["case"], "gen")

# println("pg")
# acgens[acgens[:gen_bus].==1,:pg]*100
# println("pmax")
# acgens[acgens[:gen_bus].==1,:pmax]*100

# result = run_ac_gmd_opf(net,  solver; setting=branch_setting)
# result = run_ac_gmd_opf(net, solver)
# loadings = []
# br = nothing
# bs = nothing

# for (k,br) in output["ac"]["case"]["branch"]
#     bs = output["ac"]["result"]["solution"]["branch"][k]
#     loading = sqrt(bs["pf"]^2 + bs["qf"]^2)/(100*br["rate_a"])
#     push!(loadings, loading)
#     # println("$(br["f_bus"]), $(br["t_bus"]): $(br["rate_a"]) / $(bs["pf"]), $(bs["qf"]) => $loading")
#     @printf "%3d, %3d: %6.2f / %8.2f, %8.2f => %6.2f\n" br["f_bus"] br["t_bus"] br["rate_a"] bs["pf"] bs["qf"] loading

#     # println(br)
# end



