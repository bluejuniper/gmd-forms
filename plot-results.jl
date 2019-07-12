using JSON
using Plots

pyplot()

macro ifund(exp)
    local e = :($exp)
    isdefined(e.args[1]) ? :($(e.args[1])) : :($(esc(exp)))     
end


@ifund case = nothing

if case === nothing
    println("Start loading results")
    f = open("network.json") 
    case = JSON.parse(f)
    close(f)
    println("Done loading results")
end

# let's plot the generator power for 3 generators

study_bus_nums = [1676, 1701, 1744]
study_gen_key_set = Dict()

for b in study_bus_nums
    for (k,g) in case["gen"]
        if g["gen_bus"] in study_bus_nums
            #push!(study_gen_key_set, k)
            study_gen_key_set[k] = b
        end
    end
end

# study_gen_keys = []
# study_gen_bus_nums = []

# for k in keys(study_gen_key_set)
#     push!(study_gen_keys, k)
#     push!(study_gen_bus_nums, study_gen_key_set[k])
# end

# pg = zeros(length(case["results"]), length(study_bus_nums)) 
# qg = zeros(length(case["results"]), length(study_bus_nums)) 

# for t in 1:length(case["results"])
#     for i in 1:length(study_gen_keys)
#         k = study_gen_keys[i]
#         pg[t,i] = case["results"][t]["solution"]["gen"][k]["pg"]
#         qg[t,i] = case["results"][t]["solution"]["gen"][k]["qg"]
#     end
# end

# plot(pg)
# plot(qg)

################################################

# pshed = zeros(length(case["results"]))


# for t in 1:length(case["results"])
#     s = case["results"][t]["solution"]
#     pshed[t] = 0.0

#     for (k,b) in s["bus"] 
#         if !(b["demand_served_ratio"] === nothing)
#             pshed[t] += b["pd"]*b["demand_served_ratio"]
#         end
#     end
# end

# plot(pshed)

###############################################

pg = zeros(length(case["results"]))
qg = zeros(length(case["results"]))


for t in 1:length(case["results"])
    s = case["results"][t]["solution"]
    pg[t] = 0.0
    qg[t] = 0.0

    for (k,g) in s["gen"] 
        pg[t] += g["pg"]
        qg[t] += g["qg"]
    end
end

plot(pg)
# plot(qg)





