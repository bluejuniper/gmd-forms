using PowerModels, PowerModelsGMD, Ipopt, JuMP, JSON
#CSV, DataFrames

# include("thermal-variable.jl")
# include("thermal-constraint.jl")
# include("thermal-constraint-template.jl")

const PMgmd = PowerModelsGMD

# -- F U N C T I O N S -- #

# FUNCTION: convinience function
# function run_gic_opf_ts(file, model_constructor, solver; kwargs...)
#     return run_model(file, model_constructor, solver, post_gic_opf_ts; multinetwork=true, kwargs...)
# end


# # FUNCTION: problem formulation
# function post_gic_opf_ts(pm::GenericPowerModel)
#     for (n, network) in nws(pm)
#         PowerModels.variable_voltage(pm, nw=n)
#         PowerModelsGMD.variable_dc_voltage(pm, nw=n)
#         PowerModelsGMD.variable_dc_current_mag(pm, nw=n)
#         PowerModelsGMD.variable_qloss(pm, nw=n)
#         PowerModels.variable_generation(pm, nw=n)
#         PowerModels.variable_branch_flow(pm, nw=n)
#         PowerModels.variable_dcline_flow(pm, nw=n)
#         PowerModelsGMD.variable_dc_line_flow(pm, nw=n)

#         variable_delta_oil_ss(pm, nw=n)
#         variable_delta_oil(pm, nw=n)

#         PowerModels.constraint_model_voltage(pm, nw=n)

#         for i in PowerModels.ids(pm, :ref_buses, nw=n)
#             PowerModels.constraint_theta_ref(pm, i, nw=n)
#         end

#         for i in PowerModels.ids(pm, :bus, nw=n)
#             PowerModelsGMD.constraint_kcl_gmd(pm, i, nw=n)
#         end

#         for i in PowerModels.ids(pm, :branch, nw=n)
#             PowerModelsGMD.constraint_dc_current_mag(pm, i, nw=n)
#             PowerModelsGMD.constraint_qloss_vnom(pm, i, nw=n)

#             PowerModels.constraint_ohms_yt_from(pm, i, nw=n)
#             PowerModels.constraint_ohms_yt_to(pm, i, nw=n)

#             PowerModels.constraint_voltage_angle_difference(pm, i, nw=n)

#             PowerModels.constraint_thermal_limit_from(pm, i, nw=n)
#             PowerModels.constraint_thermal_limit_to(pm, i, nw=n)

#             constraint_temperature_state_ss(pm, i, nw=n)
#         end

#         ### DC network constraints ###
#         for i in PowerModels.ids(pm, :gmd_bus)
#             PowerModelsGMD.constraint_dc_kcl_shunt(pm, i, nw=n)
#         end

#         for i in PowerModels.ids(pm, :gmd_branch)
#             PowerModelsGMD.constraint_dc_ohms(pm, i, nw=n)
#         end

#         for i in PowerModels.ids(pm, :dcline, nw=n)
#             PowerModels.constraint_dcline(pm, i, nw=n)
#         end
#     end

#     PowerModelsGMD.objective_gmd_min_fuel(pm)
# end



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
raw_net = PowerModels.parse_file(path)
raw_net["name"] = "B4GIC"
base_mva = raw_net["baseMVA"]
println("")


# Running model
println("Running model: $(raw_net["name"]) \n")
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

results = []

# Create replicates (multiples) of the network
net = PowerModels.replicate(raw_net,n)


# Update values in each replicates
for repl in keys(net["nw"])

    for i in 1:n
        #println("########## Time: $(t[i]) ########## \n")

        #update the vs values
        for (k,wf) in waveforms
            otype = wf["parent_type"]
            field  = wf["parent_field"]
            net["nw"][repl][otype][k][field] = wf["values"][i]
        end        

    end

end

result = run_gmd_opf_ts(net, PowerModelsGMD.ACPPowerModel, ipopt_solver, setting=setting)



#outfile = string("data/", net["name"], "_result.json")
#println("\nSaving results to $outfile")
#f = open(outfile,"w")
#JSON.print(f,results)
#close(f)    
 

