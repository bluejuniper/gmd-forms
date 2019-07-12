using JuMP, PowerModels

# add in realistic bounds for top-oil temperature rise
function variable_delta_oil_ss(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:ross] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_delta_oil_ss",
            lowerbound = 0,
            upperbound = 200,
            start = PowerModels.getval(ref(pm, nw, :branch, i), "delta_oil_ss_start", cnd)
        )
    else
        var(pm, nw, cnd)[:ross] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_delta_oil_ss",
            start = PowerModels.getval(ref(pm, nw, :branch, i), "delta_oil_ss_start", cnd)
        )
    end
end


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
            start = PowerModels.getval(ref(pm, nw, :branch, i), "delta_oil_start", cnd)
        )
    end
end


