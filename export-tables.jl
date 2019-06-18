using PowerModels, JSON, DelimitedFiles
include("powermodelsio.jl")

mnet = PowerModels.parse_file("/home/abarnes/.julia/environments/v1.1/dev/PowerModelsGMD/test/data/epri21.m")

f = open("data/epri21.json")
jnet = JSON.parse(f)
close(f)

mbus = to_df(mnet, "gmd_bus")
jbus = to_df(jnet, "gmd_bus")

mbr = to_df(mnet, "gmd_branch")
jbr = to_df(jnet, "gmd_branch")

cols = [:f_bus,:t_bus,:br_r,:br_v]


f = open("epri21_br_m.csv", "w")
println(f, join(cols, ","))
writedlm(f, eachrow(mbr[cols]), ',')
close(f)


mbr = to_df(mnet, "gmd_branch")
jbr = to_df(jnet, "gmd_branch")
