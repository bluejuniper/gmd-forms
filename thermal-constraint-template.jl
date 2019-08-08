### Thermal Constraints ###
using JuMP, PowerModels, Memento
include("thermal-constraint.jl")

# really should move these parameters into the model, this is rather clunky
""
function constraint_temperature_state_ss(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw, delta_oil_rated=75)
    #temperature = ref(pm, nw, :storage, i)

    branch = PMs.ref(pm, nw, :branch, i)

    if branch["topoil_time_const"] >= 0
        rate_a = branch["rate_a"]

        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)
        cnd = 1 # only support positive sequence for now

        constraint_temperature_steady_state(pm, nw, i, f_idx, cnd, rate_a, delta_oil_rated)
    end
end


""
function constraint_temperature_state(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    cnd = 1 # only support positive sequence for now

    if branch["topoil_time_const"] >= 0
        if branch["topoil_initialized"] > 0
            constraint_temperature_state_initial(pm, nw, i, f_idx, cnd, branch["topoil_init"])
        else
            constraint_temperature_state_initial(pm, nw, i, f_idx, cnd)
        end        
    end
end


""
function constraint_temperature_state(pm::GenericPowerModel, i::Int, nw_1::Int, nw_2::Int)
    branch = ref(pm, nw_1, :branch, i)

    if branch["topoil_time_const"] >= 0
        tau_oil = branch["topoil_time_const"]
        delta_t = 5

        if haskey(ref(pm, nw_1), :time_elapsed)
            delta-t = ref(pm, nw_1, :time_elapsed)
        else
            Memento.warn(_LOGGER, "network data should specify time_elapsed, using 1 as a default")
        end
        
        cnd = 1

        tau = 2*tau_oil/delta_t
        println("Oil Tau: $tau_oil, DT: $delta_t, tau: $tau")
        constraint_temperature_state(pm, nw_1, nw_2, i, cnd, tau)
    end
end


""
function constraint_hotspot_temperature_state_ss(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw)
    branch = PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    cnd = 1 # only support positive sequence for now
    rate_a = branch["rate_a"]

    if branch["topoil_time_const"] >= 0
        Re = 0.63

        if "hotspot_coeff" in keys(branch)
            Re = branch["hotspot_coeff"]
        end

        constraint_hotspot_temperature_steady_state(pm, nw, i, f_idx, cnd, rate_a, Re)
    end
end


# really should move these parameters into the model, this is rather clunky
""
function constraint_hotspot_temperature_state(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    cnd = 1 # only support positive sequence for now

    if branch["topoil_time_const"] >= 0
        constraint_hotspot_temperature(pm, nw, i, f_idx, cnd)
    end
end