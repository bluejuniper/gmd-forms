using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

# function update_vdc_unif(case, Eew, Ens)
# end



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
 




