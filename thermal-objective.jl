using JuMP, PowerModels

function objective_gmd_min_transformer_heating(pm::PMs.GenericPowerModel)
    #@assert all(!PMs.ismulticonductor(pm) for n in PMs.nws(pm))

    #i_dc_mag = Dict(n => pm.var[:nw][n][:i_dc_mag] for n in nws) #pm.var[:i_dc_mag]
    #pg = Dict(n => pm.var[:nw][n][:pg] for n in nws) #pm.var[:pg]

    # TODO: add i_dc_mag minimization

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            sum( PMs.var(pm, n, c, :ross, i) for c in PMs.conductor_ids(pm, n) )
        for (i,branch) in nw_ref[:branch])
    for (n, nw_ref) in PMs.nws(pm))
    )

end



