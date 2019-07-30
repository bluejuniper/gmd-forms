### Thermal Constraints ###
using JuMP, PowerModels
include("thermal-constraint.jl")

#""
#function constraint_temperature_exchange(pm::GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
#    temperature = ref(pm, nw, :storage, i)
#
#    constraint_temperature_complementarity(pm, nw, i)
#    constraint_temperature_loss(pm, nw, i, temperature["storage_bus"], temperature["r"][cnd], temperature["x"][cnd], temperature["standby_loss"])
#end

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
    #temperature = ref(pm, nw, :storage, i)

    # if haskey(pm.data, "time_elapsed")
    #     time_elapsed = pm.data["time_elapsed"]
    # else
    #     warn("network data should specify time_elapsed, using 1.0 as a default")
    #     time_elapsed = 1.0
    # end

    branch = ref(pm, nw, i)
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

""
function constraint_temperature_state(pm::GenericPowerModel, i::Int, nw_1::Int, nw_2::Int, tau_oil=4260, delta_t=10)
#    temperature = ref(pm, nw_2, :storage, i)

#    if haskey(pm.data, "time_elapsed")
#        time_elapsed = pm.data["time_elapsed"]
#    else
#        warn("network data should specify time_elapsed, using 1.0 as a default")
#        time_elapsed = 1.0
#    end

    tau = 2*tau_oil/delta_t
   constraint_temperature_state(pm, nw_1, nw_2, i, tau)
end
