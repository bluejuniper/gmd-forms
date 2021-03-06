using JuMP, PowerModels

### Temperature constraints ###
# i is index of the (transformer) branch
# fi is index of the "from" branch terminal
function constraint_temperature_steady_state(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, rate_a, delta_oil_rated)   where T <: PowerModels.AbstractACPForm
    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = PMs.var(pm, n, c, :p, fi) # real power
    q_fr = PMs.var(pm, n, c, :q, fi) # reactive power
    delta_oil_ss = PMs.var(pm, n, c, :ross, i) # top-oil temperature rise
    # JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)
    # ARGHHHH...Why doesn't the objective make the inequality tight???!!!
    # JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated == p_fr^2 + q_fr^2)
    JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)
    #println("Branch $i[$n] delta_hotspot_ss = 100")
    #JuMP.@constraint(pm.model, delta_oil_ss == 150)
end


function constraint_temperature_steady_state(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, rate_a, delta_oil_rated)   where T <: PowerModels.AbstractDCPForm
    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = PMs.var(pm, n, c, :p, fi) # real power
    delta_oil_ss = PMs.var(pm, n, c, :ross, i) # top-oil temperature rise
    # JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)
    # ARGHHHH...Why doesn't the objective make the inequality tight???!!!
    # JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated == p_fr^2 + q_fr^2)
    JuMP.@constraint(pm.model, sqrt(rate_a)*delta_oil_ss/sqrt(delta_oil_rated) >= p_fr)
    #println("Branch $i[$n] delta_hotspot_ss = 100")
    #JuMP.@constraint(pm.model, delta_oil_ss == 150)
end

# i is index of the (transformer) branch
# fi is index of the "from" branch terminal
function constraint_temperature_state_initial(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int)
   # assume that transformer starts at equilibrium 
   delta_oil = var(pm, n, c, :ro, i) 
   delta_oil_ss = var(pm, n, c, :ross, i) 
   @constraint(pm.model, delta_oil == delta_oil_ss)
end

function constraint_temperature_state_initial(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, delta_oil_init)
    delta_oil = var(pm, n, c, :ro, i) 
    @constraint(pm.model, delta_oil == delta_oil_init)
end

function constraint_temperature_state(pm::GenericPowerModel, n_1::Int, n_2::Int, i::Int, c::Int, tau)
   delta_oil_ss = var(pm, n_2, c, :ross, i) 
   delta_oil_ss_prev = var(pm, n_1, c, :ross, i)
   delta_oil = var(pm, n_2, c, :ro, i) 
   delta_oil_prev = var(pm, n_1, c, :ro, i)

   @constraint(pm.model, (1 + tau)*delta_oil == delta_oil_ss + delta_oil_ss_prev - (1 - tau)*delta_oil_prev)
   #@constraint(pm.model, delta_oil == delta_oil_ss)
end

function constraint_hotspot_temperature_steady_state(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, rate_a, Re)
    # return delta_oil_rated*K^2
    # println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    ieff = PMs.var(pm, n, c, :i_dc_mag)[i]
    delta_hotspot_ss = PMs.var(pm, n, c, :hsss, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, delta_hotspot_ss == Re*ieff)
    #JuMP.@constraint(pm.model, delta_hotspot_ss == 100)
end


function constraint_hotspot_temperature(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int)
    delta_hotspot_ss = PMs.var(pm, n, c, :hsss, i) 
    delta_hotspot = PMs.var(pm, n, c, :hs, i) 
    oil_temp = PMs.var(pm, n, c, :ro, i)
    JuMP.@constraint(pm.model, delta_hotspot == delta_hotspot_ss) 
end


function constraint_absolute_hotspot_temperature(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, temp_ambient)
    delta_hotspot = PMs.var(pm, n, c, :hs, i) 
    #delta_hotspot = PMs.var(pm, n, c, :hsss, i) 
    hotspot = PMs.var(pm, n, c, :hsa, i)     
    oil_temp = PMs.var(pm, n, c, :ro, i)
    JuMP.@constraint(pm.model, hotspot == delta_hotspot + oil_temp + temp_ambient) 
end


function constraint_avg_absolute_hotspot_temperature(pm::GenericPowerModel, i::Int, fi, c::Int, max_temp)
    N = length(PMs.nws(pm))
    JuMP.@constraint(pm.model, sum(PMs.var(pm, n, c, :hsa, i) for (n, nw_ref) in PMs.nws(pm)) <= N*max_temp)
end
