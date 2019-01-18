### Thermal Constraints ###
using PowerModels

#""
#function constraint_temperature_exchange(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
#    temperature = ref(pm, nw, :storage, i)
#
#    constraint_temperature_complementarity(pm, nw, i)
#    constraint_temperature_loss(pm, nw, i, temperature["storage_bus"], temperature["r"][cnd], temperature["x"][cnd], temperature["standby_loss"])
#end

# add in realistic bounds for top-oil temperature rise
function variable_delta_oil(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:ro] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_delta_oil",
            lowerbound = 0,
            upperbound = 200,
            start = PowerModels.getval(ref(pm, nw, :branch, i), "delta_oil_start", cnd)
        )
    else
        var(pm, nw, cnd)[:ro] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_delta_oil",
            start = PowerModels.getval(ref(pm, nw, :delta_oil, i), "delta_oil_start", cnd)
        )
    end
end


# really should move these parameters into the model, this is rather clunky
""
function constraint_temperature_state(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw, tau_hs=150, Re=0.63, delta_oil_init=75)
    #temperature = ref(pm, nw, :storage, i)

    if haskey(pm.data, "time_elapsed")
        time_elapsed = pm.data["time_elapsed"]
    else
        warn("network data should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    branch = ref(pm, nw, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    cnd = 1 # only support positive sequence for now

    constraint_temperature_state_initial(pm, nw, i, f_idx, cnd, delta_oil_init, tau, time_elapsed)
end

#""
#function constraint_temperature_state(pm::GenericPowerModel, i::Int, nw_1::Int, nw_2::Int)
#    temperature = ref(pm, nw_2, :storage, i)
#
#    if haskey(pm.data, "time_elapsed")
#        time_elapsed = pm.data["time_elapsed"]
#    else
#        warn("network data should specify time_elapsed, using 1.0 as a default")
#        time_elapsed = 1.0
#    end
#
#    constraint_temperature_state(pm, nw_1, nw_2, i, temperature["charge_efficiency"], temperature["discharge_efficiency"], time_elapsed)
#end
