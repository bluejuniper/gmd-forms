using Ipopt, PowerModels, PowerModelsGMD, JuMP

function run_ac_gic_opf_flat(file, solver; kwargs...)
    return run_generic_model(file, PowerModelsGMD.ACPPowerModel, solver, post_gic_opf_flat; solution_builder = PowerModelsGMD.get_gmd_solution, kwargs...)
end

function run_gic_opf_flat(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gic_opf_flat; solution_builder = PowerModelsGMD.get_gmd_solution, kwargs...)
end

"Basic GMD Model - Minimizes Generator Dispatch"
function post_gic_opf_flat{T}(pm::GenericPowerModel{T}; kwargs...)

    println(keys(pm.ref[:nw][0]))
    PowerModels.variable_voltage(pm)
    PowerModelsGMD.variable_dc_voltage(pm)
    PowerModelsGMD.variable_dc_current_mag(pm)
    PowerModelsGMD.variable_qloss(pm)
    PowerModels.variable_generation(pm)
    PowerModels.variable_branch_flow(pm)
    PowerModelsGMD.variable_dc_line_flow(pm)

    PowerModelsGMD.objective_gic_min_fuel(pm)

    PowerModels.constraint_voltage(pm)

    for i in ids(pm, :ref_buses)
        PowerModels.constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        PowerModelsGMD.constraint_kcl_gic(pm, i)
    end

    for i in ids(pm, :branch)
        #debug(LOGGER, @sprintf "Adding constraints for branch %d\n" i)
        PowerModelsGMD.constraint_dc_current_mag(pm, i)
        PowerModelsGMD.constraint_qloss_vnom(pm, i)

        PowerModels.constraint_ohms_yt_from(pm, i) 
        PowerModels.constraint_ohms_yt_to(pm, i) 

        #Why do we have the thermal limits turned off?
        #PowerModels.constraint_thermal_limit_from(pm, i)
        #PowerModels.constraint_thermal_limit_to(pm, i)
        PowerModels.constraint_voltage_angle_difference(pm, i)
    end

    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
        PowerModelsGMD.constraint_dc_kcl_shunt(pm, i)
    end

    for i in ids(pm, :gmd_branch)
        PowerModelsGMD.constraint_dc_ohms(pm, i)
    end
end



path = "data/b4gic.m"
net = PowerModels.parse_file(path)
net["multinetwork"] = false

ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
result = run_ac_gic_opf_flat(net, ipopt_solver; setting=setting)

 




