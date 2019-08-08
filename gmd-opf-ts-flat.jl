using PowerModels, PowerModelsGMD, Ipopt, JuMP, JSON, Plots, Memento
#CSV, DataFrames

const _LOGGER = Memento.getlogger(@__MODULE__)
const PMs = PowerModels

include("thermal-variable.jl")
include("thermal-constraint.jl")
include("thermal-constraint-template.jl")
include("thermal-solution.jl")
include("thermal-objective.jl")

# -- F U N C T I O N S -- #

# FUNCTION: convinience function
function run_gic_opf_ts(file, model_constructor, solver; kwargs...)
    return run_model(file, model_constructor, solver, post_gic_opf_ts; solution_builder = get_gmd_ts_solution, multinetwork=true, kwargs...)
end


# FUNCTION: problem formulation
function post_gic_opf_ts(pm::GenericPowerModel)
    for (n, network) in nws(pm)
        PMs.variable_voltage(pm, nw=n) 
        PMs.variable_generation(pm, nw=n) 
        PMs.variable_branch_flow(pm, nw=n) 
        PMs.variable_dcline_flow(pm, nw=n) 

        PowerModelsGMD.variable_dc_voltage(pm, nw=n)
        PowerModelsGMD.variable_dc_current_mag(pm, nw=n)
        PowerModelsGMD.variable_qloss(pm, nw=n)
        PowerModelsGMD.variable_dc_line_flow(pm, nw=n)

        variable_delta_oil_ss(pm, nw=n)
        variable_oil_ss(pm, nw=n)
        variable_delta_oil(pm, nw=n)
        variable_delta_hotspot_ss(pm, nw=n)
        variable_delta_hotspot(pm, nw=n)

        PMs.constraint_model_voltage(pm, nw=n)

        for i in PMs.ids(pm, :ref_buses, nw=n)
            PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :bus, nw=n)
            PowerModelsGMD.constraint_kcl_gmd(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :branch, nw=n)
            PowerModelsGMD.constraint_dc_current_mag(pm, i, nw=n)
            PowerModelsGMD.constraint_qloss_vnom(pm, i, nw=n)

            PMs.constraint_ohms_yt_from(pm, i, nw=n)
            PMs.constraint_ohms_yt_to(pm, i, nw=n)

            PMs.constraint_voltage_angle_difference(pm, i, nw=n)

            PMs.constraint_thermal_limit_from(pm, i, nw=n)
            PMs.constraint_thermal_limit_to(pm, i, nw=n)

            constraint_temperature_rise_ss(pm, i, nw=n) 
            constraint_temperature_state_ss(pm, i, nw=n) 
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)             
            constraint_hotspot_temperature_state(pm, i, nw=n)                         
        end

        ### DC network constraints ###
        for i in PMs.ids(pm, :gmd_bus)
            PowerModelsGMD.constraint_dc_kcl_shunt(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :gmd_branch)
            PowerModelsGMD.constraint_dc_ohms(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :dcline, nw=n)
            PMs.constraint_dcline(pm, i, nw=n)
        end
    end

    network_ids = sort(collect(nw_ids(pm)))

    n_1 = network_ids[1]
    for i in ids(pm, :branch, nw=n_1)
        constraint_temperature_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in ids(pm, :branch, nw=n_2)
            constraint_temperature_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    objective_gmd_min_transformer_heating(pm)
end

println("")

# Load waveform data
# Not using for now
println("Load waveform data\n")
wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
wf_data = JSON.parse(h)
close(h)




# Load case data
println("Load case data\n")
# path = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/b4gic.m")
path = "data/b4gic_thermal.m"
raw_net = PMs.parse_file(path)
raw_net["name"] = "B4GIC"
base_mva = raw_net["baseMVA"]
println("")


# timesteps = wf_data["time"]
# n = length(timesteps)
T = 60*3
n = Int(ceil(T/raw_net["time_elapsed"]))
t = range(0, stop=T, length=n)
delta_t = raw_net["time_elapsed"]
# not using for now
waveforms = wf_data["waveforms"]

# Running model
solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

results = []

mod_net = deepcopy(raw_net)

mva_base = 100
mod_net["load"]["1"]["pd"] = 1000/mva_base
mod_net["load"]["1"]["qd"] = 200/mva_base

mod_net["gmd_branch"]["2"]["br_v"] = 100

# Create replicates (multiples) of the network
net = PMs.replicate(mod_net, n)

println("Running model: $(raw_net["name"]) \n")
results = run_gic_opf_ts(net, PowerModelsGMD.ACPPowerModel, solver; setting=setting)
println("Done running model")

termination_status = results["termination_status"]
primal_status = results["primal_status"]
objective = results["objective"]
println("Termination status $termination_status")
println("Primal status $primal_status")
println("Objective $objective")

output = Dict()
output["case"] = net
output["result"] = results

outfile = string("data/", raw_net["name"], "_gmd_opf_ts.json")
println("\nSaving results to $outfile")
f = open(outfile,"w")
JSON.print(f,output)
close(f)    




 

