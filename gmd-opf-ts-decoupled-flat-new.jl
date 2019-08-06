using PowerModels, PowerModelsGMD, Ipopt
using JSON, JuMP, CSV, DataFrames


# -- F U N C T I O N S -- #

# FUNCTION: AC-OPF using calculated quasi-dc currents
function run_sample(net, ipopt_solver, setting)
    data = PowerModelsGMD.run_ac_gmd_opf_decoupled(net, ipopt_solver; setting=setting)
    ac_solution = data["ac"]["result"]["solution"]
    return data 

end


# FUNCTION: calculate steady-state top oil temperature rise
function ss_top_oil_rise(branch, result, base_mva; delta_rated=75)
    if !branch["transformer"]
        return 0
    end

    i = branch["index"]
    bs = result["solution"]["branch"]["$i"]
    S = sqrt(bs["pf"]^2 + bs["qf"]^2)
    K = S/(base_mva*branch["rate_a"]) #calculate the loading

    println("S: $S \nSmax: $(branch["rate_a"]) \n")
    #assumptions: no-load, transformer losses are very small 
    # 75 = top oil temp rise at rated power
    # 30 = ambient temperature
    return delta_rated*K^2

end


# FUNCTION: calculate top-oil temperature rise
function top_oil_rise(branch, result; tau_oil=4260, Delta_t=10)
    # tau_oil = 71 mins

    delta_oil_ss = ss_top_oil_rise(branch, result, base_mva)
    #delta_oil_ss = 1 #testing for step response
    delta_oil = delta_oil_ss # if 1st iteration, assume it starts from steady-state value

    if ("delta_oil" in keys(branch) && "delta_oil_ss" in keys(branch))
        println("Updating oil temperature")
        delta_oil_prev = branch["delta_oil"]
        delta_oil_ss_prev = branch["delta_oil_ss"] 

        # trapezoidal integration
        tau = 2*tau_oil/Delta_t
        delta_oil = (delta_oil_ss + delta_oil_ss_prev)/(1 + tau) - delta_oil_prev*(1 - tau)/(1 + tau)
    else
        delta_oil = 0
        println("Setting initial oil temperature")
    end

   branch["delta_oil_ss"] = delta_oil_ss 
   branch["delta_oil"] = delta_oil

end


# FUNCTION: calculate steady-state hotspot temperature rise for the time-extension mitigation problem
function ss_hotspot_rise(branch, result; Re=0.63)
    delta_hs = 0
    Ie = branch["ieff"]
    delta_hs = Re*Ie
    branch["delta_hs"] = delta_hs

end


# FUNCTION: calculate hotspot temperature rise for the time-extension mitigation problem
function hotspot_rise(branch, result, Ie_prev; tau_hs=150, Delta_t=10, Re=0.63)
    # 'Re': from Randy Horton's report, transformer model E on p. 52
    
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


# FUNCTION: update top-oil temperature rise for the network
function update_top_oil_rise(branch, net)
    k = "$(branch["index"])"
    net["branch"][k]["delta_oil"] = branch["delta_oil"]
    net["branch"][k]["delta_oil_ss"] = branch["delta_oil_ss"]
end



# FUNCTION: update hotspot temperature rise for the network
 function update_hotspot_rise(branch, net)
    k = "$(branch["index"])"
    net["branch"][k]["delta_hs"] = branch["delta_hs"]
end



# -- T E S T I N G -- #

println("")

# Load waveform data
println("Load waveform data\n")
wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
wf_data = JSON.parse(h)
close(h)

timesteps = wf_data["time"]
n = length(timesteps)
t = range(0, stop=(3600*3*3), length=n)
Delta_t = t[2]-t[1]
waveforms = wf_data["waveforms"]


# Load case data
println("Load case data\n")
path = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/b4gic.m")
net = PowerModels.parse_file(path)
net["name"] = "B4GIC"
base_mva = net["baseMVA"]
println("")




# Running model
println("Running model: $(net["name"]) \n")
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

results = [];
Ie_prev = Dict();

    #pust out results
    out_ieff = []
    out_to = []
    out_to_ss = []
    out_ths = []
    ac_results = []

for (k,br) in net["branch"]
  Ie_prev[k] = nothing
end

for i in 1:n
    println("########## Time: $(t[i]) ########## \n")

    # update the vs values
    for (k,wf) in waveforms
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        net[otype][k][field] = wf["values"][i]
    end

    println("Start running base opf")
    data = run_sample(net, ipopt_solver, setting)
    println("Done running base opf\n")

    data["time_index"] = i
    data["time"] = t[i]

    #ac_solution = data["ac"]["result"]["solution"]
    push!(results, data)
    #push!(ac_results, ac_solution)
    

    for (k,br) in data["ac"]["case"]["branch"]
        if !(br["transformer"] == true)
            continue
        end

        br_acs = data["ac"]["result"]["solution"]["branch"][k]
        p = br_acs["pf"]
        q = br_acs["qf"]
  
        #to = ss_top_oil_rise(br, data["ac"]["result"])
        result = data["ac"]["result"]

        top_oil_rise(br, result; Delta_t = Delta_t)
        update_top_oil_rise(br, net)

        ss_hotspot_rise(br, result)
        #hotspot_rise(br, result, Ie_prev[k]) #decieded to only use stead-state value
        update_hotspot_rise(br, net)

        Ie_prev[k] = br["ieff"]
        to = br["delta_oil"]
        to_ss = br["delta_oil_ss"]
        ths = br["delta_hs"]
        
        println("Ieff: $(br["ieff"]) \nOil temp. rise: $to \nSteady-state oil temp. rise: $to_ss \nHotspot temp. rise: $ths \n")

        #pushing out results...
        if (k == "1")

            #Ieff
            push!(out_ieff, br["ieff"])

            #Oil temp. rise
            push!(out_to, br["delta_oil"])

            #Steady-state oil temp. rise
            push!(out_to_ss, br["delta_oil_ss"])

            #Hotspot temp. rise
            push!(out_ths, br["delta_hs"])

        end

    end
end


# Save results to output
outfile = string("data/", net["name"], "_gmd_opf_ts_decoupled.json")
#outfile = string("data/", net["name"], "-time-ext-result.json")
println("\nSaving results to $outfile")
f = open(outfile,"w")
JSON.print(f,results)
close(f)


