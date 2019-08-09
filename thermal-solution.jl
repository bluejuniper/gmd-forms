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

    add_setpoint_top_oil_rise_steady_state!(sol, pm)
    add_setpoint_top_oil_rise!(sol, pm)
    add_setpoint_hotspot_rise_steady_state!(sol, pm)
    add_setpoint_hotspot_rise!(sol, pm)
    add_setpoint_hotspot_temperature!(sol, pm)

end

function add_setpoint_top_oil_rise_steady_state!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "topoil_rise_ss", :ross, status_name="br_status")
end


function add_setpoint_top_oil_rise!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "topoil_rise", :ro, status_name="br_status")
end

function add_setpoint_hotspot_rise_steady_state!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "hotspot_rise_ss", :hsss, status_name="br_status")
end

function add_setpoint_hotspot_rise!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "hotspot_rise", :hs, status_name="br_status")
end

function add_setpoint_hotspot_temperature!(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "hotspot", :hsa, status_name="br_status")
end