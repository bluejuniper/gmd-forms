using JuMP, PowerModels

# add in realistic bounds for top-oil steady-state temperature rise
function variable_delta_oil_ss(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        PMs.var(pm, nw, cnd)[:ross] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil_ss",
            lower_bound = 0,
            upper_bound = 200,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_ss_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:ross] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil_ss",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_ss_start", cnd)
        )
    end
end


# add in realistic bounds for top-oil temperature rise
function variable_delta_oil(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        PMs.var(pm, nw, cnd)[:ro] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil",
            lower_bound = 0,
            upper_bound = 200,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:ro] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_start", cnd)
        )
    end
end


