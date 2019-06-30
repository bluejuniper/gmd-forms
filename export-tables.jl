using PowerModels, PowerModelsGMD, JSON, DelimitedFiles, JuMP, Ipopt
include("powermodelsio.jl")

mnet = PowerModels.parse_file("/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/epri21.m")

f = open("data/epri21.json")
jnet = JSON.parse(f)
close(f)

for (k,x) in jnet["gmd_bus"]
    x["status"] = 1
end

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
println("Start solving")
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
result = run_gmd(jnet, ipopt_solver; setting=setting)
println("Done solving")


function write_csv(df, cols, filename)
    f = open(filename, "w")
    println(f, join(cols, ","))
    writedlm(f, eachrow(df[cols]), ',')
    close(f)
end


mbus = to_df(mnet, "gmd_bus")
jbus = to_df(jnet, "gmd_bus"; solution=result["solution"])

cols = [:index, :g_gnd]
write_csv(mbus, cols, "epri21_bus_mpwr.csv")
cols = [:index, :g_gnd, :parent_type, :parent_index, :gmd_vdc]
write_csv(jbus, cols, "epri21_bus_json.csv")

mbr = to_df(mnet, "gmd_branch")
jbr = to_df(jnet, "gmd_branch"; solution=result["solution"])

cols = [:f_bus,:t_bus,:br_r,:br_v]
write_csv(mbr, cols, "epri21_br_mpwr.csv")
cols = [:f_bus, :t_bus, :br_r, :br_v, :parent_name, :parent_index, :gmd_idc]
write_csv(jbr, cols, "epri21_br_json.csv",)



