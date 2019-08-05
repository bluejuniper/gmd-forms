### Thermal Constraints ###
using JuMP, PowerModels, Memento
include("thermal-constraint.jl")

# really should move these parameters into the model, this is rather clunky
""
function constraint_temperature_state_ss(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw, delta_oil_rated=75)
    #temperature = ref(pm, nw, :storage, i)

    branch = PMs.ref(pm, nw, :branch, i)
    rate_a = branch["rate_a"]

    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    cnd = 1 # only support positive sequence for now

    constraint_temperature_steady_state(pm, nw, i, f_idx, cnd, rate_a, delta_oil_rated)
end


# really should move these parameters into the model, this is rather clunky
""
function constraint_temperature_state(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw, delta_oil_init=nothing)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    cnd = 1 # only support positive sequence for now

    if delta_oil_init === nothing
        constraint_temperature_state_initial(pm, nw, i, f_idx, cnd)
    else
        constraint_temperature_state_initial(pm, nw, i, f_idx, cnd, delta_oil_init)
    end        
end

# need to add tau_oil into the model
""
function constraint_temperature_state(pm::GenericPowerModel, i::Int, nw_1::Int, nw_2::Int, tau_oil=150)
    if haskey(ref(pm, nw_1), :time_elapsed)
        delta-t = ref(pm, nw_1, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network data should specify time_elapsed, using 10 as a default")
        delta_t = 10.0
    end
    
    cnd = 1

    tau = 2*tau_oil/delta_t
   constraint_temperature_state(pm, nw_1, nw_2, i, cnd, tau)
end
