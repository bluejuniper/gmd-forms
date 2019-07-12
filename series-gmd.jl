using Ipopt, PowerModels, PowerModelsGMD, JSON

macro ifund(exp)
    local e = :($exp)
    isdefined(e.args[1]) ? :($(e.args[1])) : :($(esc(exp)))     
end


function run_sample(data,ipopt_solver,setting)
    result = run_ac_gmd(data, ipopt_solver, setting=setting)

    # convert gen setpoints back to si
    Sb = data["baseMVA"]

    for (gkey,g) in result["solution"]["gen"]
        g["pg"] *= Sb
        g["qg"] *= Sb
    end

    return result
end


function branch_overloaded(br,br_sol)
    p_fr = br_sol["pf"]
    q_fr = br_sol["qf"]
    p_to = br_sol["pt"]
    q_to = br_sol["qt"]

    # TODO: check if the correct data hash is being passed in
    rate_a = br["rate_a"]*data["baseMVA"]
    sfr = sqrt(p_fr^2 + q_fr^2)
    sto = sqrt(p_to^2 + q_to^2)

    if sfr > 1.1*rate_a || sto > 1.1*rate_a
        @printf "!!!VIOlATION ON BRANCH[%s] %s (%s,%s): " br["index"] br["name"] br["f_bus"] br["t_bus"]
        @printf "sf = %f, st = %f, smax = %f!!!\n" sfr sto rate_a
        return true
    end

    return false
end

function gen_overramped(gen,gen_sol)
    p = gen_sol["pg"]
    q = gen_sol["qq"]

    p0 = gen["pg"]
    q0 = gen["pg"]
    hed = zeros(length(case["results"]))


    # for t in 1:length(case["results"])
    #     s = case["results"][t]["solution"]
    #     pshed[t] = 0.0

    #     for (k,b) in s["bus"] 
    #         if !(b["demand_served_ratio"] === nothing)
    #             pshed[t] += b["pd"]*b["demand_served_ratio"]
    #         end
    #     end
    # end

    # plot(pshed)ount += 1

    pmax = gen["pmax"]
    qmax = gen["qmax"]

    dp = abs(p - p0)
    dq = abs(q - q0)



    if dp >= 0.1*pmax || dq >= 0.1*qmax
        @printf "!!!VIOlATION ON GEN[%d] at %d: " gen["index"] gen["gen_bus"]
        @printf "p = %f, q = %f, p0 = %f, q0 = %f, pmax = %f, qmax = %f !!!\n" p q p0 q0 pmax qmax
        return true
    end

    return false
end

# return breaker status
function breaker_closed(br,br_sol)
    return br["br_status"] # disable opening branch breakers

    if !branch_overloaded(br,br_sol)
        return br["br_status"]
    end


    # disable the branch status
    # can disable the branch if either breaker is ok
    # branch is overloaded and bother breakers are non-operational
    if br["f_breaker_damaged"] && br["t_breaker_damaged"]
        return br["br_status"]
    end

    # branch is overloaded and  at least one breaker is operational, open
    return false
end

function gen_breaker_closed(gen, gen_sol)
    if !gen_overramped(gen, gen_sol)
        return gen["gen_status"]
    end

    return false
end

 
function update_breakers(data,result)
    for (key,br_sol) in result["solution"]["branch"]
        br = data["branch"][key]
        br_sol["br_status"] = data["branch"][key]["br_status"]
        br_sol["br_status"] = breaker_closed(br,br_sol)
        br["br_status"] = br_sol["br_status"]
        #br["br_status"] = true
    end
end

function update_gen_breakers(data,result)
    for (key,gen_sol) in result["solution"]["gen"]
        gen = data["branch"][key]
        gen_sol["gen_status"] = data["gen"][key]["gen_status"]
        gen_sol["gen_status"] = gen_breaker_closed(gen,gen_sol)
        gen["br_status"] = gen_sol["gen_status"]
        #br["br_status"] = true
    end
end


if length(ARGS) > 0
  @printf "Number of args: %d, first arg: %s" length(ARGS) ARGS[1]
  path = ARGS[1]
end

#@ifund path = "data/b4gic.json"
#@ifund path = "data/epri21.json"
#@ifund path = "data/uiuc150_gmd.json"
@ifund path = "data/texas2000_gmd.json"
raw_data = PowerModels.parse_file(path)
data = copy(raw_data)
@printf "Running model %s\n" data["name"]


ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))

efield = data["field"]
waveforms = data["waveforms"]
t = data["time"]
delete!(data,"field")
delete!(data,"waveforms")
delete!(data,"time")

if efield === nothing
    m = data["gmd_e_field_mag"]
    d = data["gmd_e_field_dir"]
    theta = (90.0 - d)*pi/180.0

    efield = [m*[cos(d), sin(d)]]
end


##### Run initial case with OPF and no GMD #####
# update the vs values
# for (key,wf) in waveforms
#     data["gmd_branch"][key]["br_v"] = 0.0
# end
for (key,br) in data["gmd_branch"]
    br["br_v"] = 0.0
    #println(br)
end


setting["objective"] = "min_fuel"
result = run_sample(data,ipopt_solver,setting)
update_breakers(data, result)

for (key,br_sol) in result["solution"]["gmd_branch"]
    br_sol["br_v"] = 0.0
end


results = [result]
violations = []

##### Run the rest of the time series with GMD #####
setting["objective"] = "min_error"
tic()


count = 1
for i in 1:100:min(length(t),3000)
    # f = efield["values"][i]
    @printf "\n\n########## Time: %0.3f ##########\n" t[i]

    # update the vs values
    for (key,wf) in waveforms
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        data[otype][key][field] = wf["values"][i]
    end

    # update the generator setpoints to the last time step
    for (key,gen) in results[1]["solution"]["gen"]
        data["gen"][key]["pg"] = gen["pg"]/data["baseMVA"]
        data["gen"][key]["qg"] = gen["qg"]/data["baseMVA"]
    end

    #data["branch"]["2"]["br_status"] = false

    println("Generators:")
    #println(data["gen"])
    println("Start running base opf")
    result = run_sample(data,ipopt_solver,setting)
    println("Done running base opf")
    #println("Generators:")
    #println(data["gen"])

    # need to add "frozen/fixed" field for branches/buses

    # check for violations
    update_breakers(data, result)

    for (key,br_sol) in result["solution"]["gmd_branch"]
        br_sol["br_v"] = 0.0
    end

    # update the vs values
    for (key,wf) in waveforms
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        gmd_br = data[otype][key]

        if otype == "gmd_branch"
            # not sure if need results in both places... :/
            result["solution"]["gmd_branch"][key]["br_v"] = wf["values"][i]
            gmd_key = string(gmd_br["parent_index"])
            result["solution"]["branch"][gmd_key]["gmd_vdc"] = wf["values"][i]
        end
    end
    
    result["time_index"] = i
    push!(results,result)
end

runtime = toc()

outfile = string("data/", data["name"], "_result.json")
f = open(outfile,"w")
JSON.print(f,results)
close(f)    
 


data["results"] = results
data["field"] = efield
data["waveforms"] = waveforms

# calculate the centroid of subs
lat = 0.0
lon = 0.0

for sub in values(data["sub"])
    lat += sub["lat"]
    lon += sub["lon"]
end

data["lat_center"] = lat/length(data["sub"])
data["lon_center"] = lon/length(data["sub"])

# file name used by index.html
f = open("network.json","w")
JSON.print(f,data)
close(f) 



