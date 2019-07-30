function get_gmd_ts_solution(pm::PMs.GenericPowerModel, sol::Dict{String,Any})
    PMs.add_setpoint_bus_voltage!(sol, pm)
    PMs.add_setpoint_generator_power!(sol, pm)
    PMs.add_setpoint_branch_flow!(sol, pm)

    PowerModelsGMD.add_setpoint_load_demand!(sol, pm)
    PowerModelsGMD.add_setpoint_bus_dc_voltage!(sol, pm)
    PowerModelsGMD.add_setpoint_bus_dc_current_mag!(sol, pm)
    PowerModelsGMD.add_setpoint_load_shed!(sol, pm)
    PowerModelsGMD.add_setpoint_branch_dc_flow!(sol, pm)
    PowerModelsGMD.add_setpoint_bus_qloss!(sol, pm)

    add_setpoint_temperature_steady_state!(sol, pm)
    add_setpoint_temperature!(sol, pm)
end

function add_setpoint_temperature_steady_state!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "delta_topoilrise_ss", :ross, status_name="br_status")
end

function add_setpoint_temperature!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "delta_topoilrise", :ro, status_name="br_status")
end
