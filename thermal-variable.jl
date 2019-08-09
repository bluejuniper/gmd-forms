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


function variable_absolute_oil_ss(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        PMs.var(pm, nw, cnd)[:rossa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_oil_ss",
            lower_bound = -277,
            upper_bound = 200,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "oil_ss_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:rossa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_oil_ss",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "oil_ss_start", cnd)
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


function variable_delta_hotspot_ss(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        PMs.var(pm, nw, cnd)[:hsss] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot_ss",
            lower_bound = 0,
            upper_bound = 200,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_hotspot_ss_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:hsss] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot_ss",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_hotspot_start", cnd)
        )
    end
end

function variable_delta_hotspot(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        PMs.var(pm, nw, cnd)[:hs] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot",
            lower_bound = 0,
            upper_bound = 200,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_hotspot_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:hs] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_hotspot_start", cnd)
        )
    end
end

function variable_hotspot(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        PMs.var(pm, nw, cnd)[:hsa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_hotspot",
            lower_bound = -277,
            upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "hotspot_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:hsa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_hotspot",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "hotspot_start", cnd)
        )
    end
end

