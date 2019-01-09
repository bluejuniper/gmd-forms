using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

# function update_vdc_unif(case, Eew, Ens)
# end


function run_sample(net, ipopt_solver, setting)
    data = PowerModelsGMD.run_ac_gic_opf_decoupled(net, ipopt_solver; setting=setting)
    ac_solution = data["ac"]["result"]["solution"]
    #println("Running make_gmd_mixed_units")
    #make_gmd_mixed_units(ac_solution, 100.0)
    #println("Running adjust_gmd_qloss")
    #adjust_gmd_qloss(net, ac_solution)
    return data
end

function ss_top_oil_rise(branch, result; delta_rated=75)
    if !branch["transformer"]
        return 0
    end
        
    i = branch["index"]
    bs = result["solution"]["branch"]["$i"]
    S = sqrt(bs["pf"]^2 + bs["qf"]^2)
    K = S/branch["rate_a"] # calculate the loading

    @printf "S: %0.3f, Smax: %0.3f\n" S branch["rate_a"]
    # this assumes that no-load transformer losses are very small
    # 75 = top oil temp rise at rated power
    # 30 = ambient temperature
    return delta_rated*K^2
end

# tau_oil = 71 mins
function top_oil_rise(branch, result; tau_oil=4260, Delta_t=10)
    delta_oil_ss = ss_top_oil_rise(branch, result)
    delta_oil = delta_oil_ss # if we are at 1st iteration then assume starts from steady-state

    if ("delta_oil" in keys(branch) && "delta_oil_ss" in keys(branch))
        println("Updating oil temperature")
        delta_oil_prev = branch["delta_oil"]
        delta_oil_ss_prev = branch["delta_oil_ss"] 


        # trapezoidal integration
        tau = 2*tau_oil/Delta_t
        delta_oil = (delta_oil_ss + delta_oil_ss_prev)/(1 + tau) - delta_oil_prev*(1 - tau)/(1 + tau)
    else
        println("Setting initial oil temperature")
    end

   branch["delta_oil_ss"] = delta_oil_ss 
   branch["delta_oil"] = delta_oil
end

# for the time-extension mitigation problem 
# Re comes from Randy Horton's report, transformer model E on p. 52
function hotspot_rise(branch, result, Ie_prev; tau_hs=150, Delta_t=10, Re=0.63)
    delta_hs = 0
    Ie = branch["ieff"]
    tau = 2*tau_hs/Delta_t

    if Ie_prev === nothing
        delta_hs = Re*Ie
    else
        delta_hs_prev = branch["delta_hs"]
        delta_hs = Re*(Ie + Ie_prev)/(1 + tau) - delta_hs_prev*(1 - tau)/(1 + tau)
    end

    branch["delta_hs"] = delta_hs
end

function update_top_oil_rise(branch, net)
    k = "$(branch["index"])"
    # update top-oil rise for the network
    net["branch"][k]["delta_oil"] = branch["delta_oil"]
    net["branch"][k]["delta_oil_ss"] = branch["delta_oil_ss"]
end

 function update_hotspot_rise(branch, net)
    k = "$(branch["index"])"
    # update top-oil rise for the network
    net["branch"][k]["delta_hs"] = branch["delta_hs"]
end


wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
wf_data = JSON.parse(h)
close(h)

t = wf_data["time"]
waveforms = wf_data["waveforms"]
n = length(t)

path = "data/b4gic.m"
raw_net = PowerModels.parse_file(path)
# fix an error in the data
raw_net["name"] = "b4gic"
raw_net["branch"]["2"]["transformer"] = false
net = copy(raw_net)
@printf "Running model %s\n" net["name"]

ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
results = []

Ie_prev = Dict()

for (k,br) in net["branch"]
  Ie_prev[k] = nothing
end

for i in 1:n
    @printf "\n\n########## Time: %0.3f ##########\n" t[i]

    # update the vs values
    for (k,wf) in waveforms
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        net[otype][k][field] = wf["values"][i]
    end

    println("Start running base opf")
    data = run_sample(net, ipopt_solver, setting)
    println("Done running base opf")

    data["time_index"] = i
    data["time"] = t[i]
    push!(results, data)

    # add the thermal model in here...
    for (k,br) in data["ac"]["case"]["branch"]
        if !(br["transformer"] == true)
            continue
        end

        br_acs = data["ac"]["result"]["solution"]["branch"][k]
        p = br_acs["pf"]
        q = br_acs["qf"]
  
        #to = ss_top_oil_rise(br, data["ac"]["result"])
        result = data["ac"]["result"]
        PowerModelsGMD.top_oil_rise(br, result)
        PowerModelsGMD.update_top_oil_rise(br, net)

        PowerModelsGMD.hotspot_rise(br, result, Ie_prev[k])
        PowerModelsGMD.update_hotspot_rise(br, net)
        Ie_prev[k] = br["ieff"]

        to = br["delta_oil"]
        to_ss = br["delta_oil_ss"]
        ths = br["delta_hs"]
        @printf "Ieff: %0.3f, Oil temp rise: %0.3f Steady-state oil temp rise: %0.3f, Hotspot temp rise %0.3f\n" br["ieff"] to to_ss ths
    end
end


outfile = string("data/", net["name"], "_result.json")
println("\nSaving results to $outfile")
f = open(outfile,"w")
JSON.print(f,results)
close(f)    
 




