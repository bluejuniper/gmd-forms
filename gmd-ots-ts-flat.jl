using PowerModels, PowerModelsGMD, Ipopt, Cbc, Juniper, JuMP, JSON, Plots, Memento
#CSV, DataFrames

include("powermodelsio.jl")

const _LOGGER = Memento.getlogger(@__MODULE__)
const PMs = PowerModels
const PG = PowerModelsGMD

include("thermal-variable.jl")
include("thermal-constraint.jl")
include("thermal-constraint-template.jl")
include("thermal-solution.jl")
include("thermal-objective.jl")

# -- F U N C T I O N S -- #

# FUNCTION: convinience function
function run_gic_ots_ts(file, model_constructor, solver; kwargs...)
    return run_model(file, model_constructor, solver, post_gic_ots_ts; ref_extensions=[PMs.ref_add_on_off_va_bounds!], solution_builder = get_gmd_ts_solution, multinetwork=true, kwargs...)
    # return run_model(file, model_constructor, solver, post_gic_ots_ts; solution_builder = get_gmd_ts_solution, multinetwork=true, kwargs...)
end


# FUNCTION: problem formulation
function post_gic_ots_ts(pm::GenericPowerModel)
    for (n, network) in nws(pm)
        PMs.variable_voltage_on_off(pm, nw=n) # theta_i and V_i, includes constraint 3o
        PMs.variable_generation(pm, nw=n) 
        PMs.variable_branch_flow(pm, nw=n) 
        PMs.variable_dcline_flow(pm, nw=n) 
        # PMs.variable_current_magnitude_sqr(pm, nw=n)

        # ac switching variables
        PMs.variable_branch_indicator(pm, nw=n) # z_e variable

        PG.variable_dc_current_mag(pm, nw=n)
        #PG.variable_dc_current(pm, nw=n)
        #PG.variable_dc_line_flow(pm; bounded=false, nw=n)
        #PG.variable_dc_voltage_on_off(pm, nw=n)
        # What is this???
        #PG.variable_reactive_loss(pm, nw=n) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)
        #PG.variable_qloss(pm, nw=n) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)        
        

    	  # GMD switching-related variables
		    #PG.variable_active_generation_sqr_cost(pm, nw=n)
        #PG.variable_load(pm, nw=n) # l_i^p, l_i^q
        #PG.variable_gen_indicator(pm, nw=n)  # z variables for the generators

        # thermal variables
        #variable_delta_oil_ss(pm, nw=n, bounded=false)
        #variable_delta_oil(pm, nw=n, bounded=false)
        #variable_delta_hotspot_ss(pm, nw=n, bounded=false)
        #variable_delta_hotspot(pm, nw=n, bounded=false)
        #variable_hotspot(pm, nw=n, bounded=false)

        PMs.constraint_model_voltage_on_off(pm, nw=n)

        for i in PMs.ids(pm, :ref_buses, nw=n)
            PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :bus, nw=n)
            #PG.constraint_kcl_shunt_gmd_ls(pm, i, nw=n)
          constraint_power_balance_shunt(pm, i, nw=n)
        end

	    #for i in PMs.ids(pm, :gen)
	    #    PG.constraint_gen_on_off(pm, i, nw=n) # variation of 3q, 3r
	    #    PG.constraint_gen_ots_on_off(pm, i, nw=n)
	    #    PG.constraint_gen_perspective(pm, i, nw=n)
	    #end

        for i in PMs.ids(pm, :branch, nw=n)
            #PG.constraint_dc_current_mag_on_off(pm, i, nw=n)
            # OTS formulation is using constraint_qloss
            #PG.constraint_qloss_vnom(pm, i, nw=n)

            PMs.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            PMs.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            PMs.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            PMs.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            PMs.constraint_thermal_limit_to_on_off(pm, i, nw=n)

            #constraint_temperature_state_ss(pm, i, nw=n) 
            #constraint_hotspot_temperature_state_ss(pm, i, nw=n)             
            #constraint_hotspot_temperature_state(pm, i, nw=n)                         
            #constraint_absolute_hotspot_temperature_state(pm, i, nw=n)            
        end

        ### DC network constraints ###
        #for i in PMs.ids(pm, :gmd_bus)
            #PG.constraint_dc_kcl_shunt(pm, i, nw=n)
        #end

        #for i in PMs.ids(pm, :gmd_branch)
            #PG.constraint_dc_ohms_on_off(pm, i, nw=n)
        #end

        for i in PMs.ids(pm, :dcline, nw=n)
            PMs.constraint_dcline(pm, i, nw=n)
        end
    end

    #for i in PMs.ids(pm, :branch, nw=1)
    #	constraint_avg_absolute_hotspot_temperature_state(pm, i)
    #end

    #network_ids = sort(collect(nw_ids(pm)))

    #n_1 = network_ids[1]
    #for i in ids(pm, :branch, nw=n_1)
    #    constraint_temperature_state(pm, i, nw=n_1)
    #end

    #for n_2 in network_ids[2:end]
    #    for i in ids(pm, :branch, nw=n_2)
    #        constraint_temperature_state(pm, i, n_1, n_2)
    #    end
    #    n_1 = n_2
    #end

    # this has multinetwork built-in
    #PG.objective_gmd_min_ls_on_off(pm) # variation of equation 3a
    PMs.objective_min_fuel_and_flow_cost(pm)

    # #PG.objective_gmd_min_fuel(pm)
    # objective_gmd_min_transformer_heating(pm)
end

println("")



# Load case data
println("Load case data\n")
path = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/epri21_ots.m")
# path = "data/b4gic_thermal.m"
raw_net = PMs.parse_file(path)
# raw_net["name"] = "B4GIC"
base_mva = raw_net["baseMVA"]
println("")


n = 1
delta_t = raw_net["time_elapsed"]
T = n*delta_t

# Running model
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-3, print_level=0)
#gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer, tol=1e-6, print_level=0)
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
#juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=ipopt_solver, mip_solver=cbc_solver, log_levels=[])
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), log_levels=[])
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

results = []

update_gmd_status!(raw_net)
mod_net = deepcopy(raw_net)
mod_net["time_elapsed"] = 60

# let's reduce the dc voltages
for (k,gbr) in mod_net["gmd_branch"]
    gbr["br_v"] /= 100
    gbr["br_v"] = 0
end

for (k,br) in mod_net["branch"]
  br["dispatchable"] = 0
end

# mod_net["gmd_branch"]["2"]["br_v"] = 100

# Create replicates (multiples) of the network
net = PMs.replicate(mod_net, n)

println("Running model: $(raw_net["name"]) \n")
# results = run_gic_opf_ts(net, PG.QCWRPowerModel, juniper_solver; setting=setting)
#results = run_gic_opf_ts(net, PG.ACPPowerModel, juniper_solver; setting=setting)
results = run_gic_ots_ts(net, PG.SOCWRPowerModel, juniper_solver; setting=setting)
#results = run_ots(net, PG.SOCWRPowerModel, juniper_solver; setting=setting)
println("Done running model")

termination_status = results["termination_status"]
primal_status = results["primal_status"]
objective = results["objective"]
println("Termination status $termination_status")
println("Primal status $primal_status")
println("Objective $objective")

PowerModels.make_mixed_units!(net)
PowerModels.make_mixed_units!(results)

output = Dict()
output["case"] = net
output["result"] = results

outfile = string("data/", raw_net["name"], "_gmd_opf_ts.json")
println("\nSaving results to $outfile")
f = open(outfile,"w")
JSON.print(f,output)
close(f)    
