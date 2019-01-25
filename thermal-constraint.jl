using PowerModelsGMD

### Temperature constraints ###

#   
#
#""
# tau_oil = 71 mins
#function top_oil_rise(branch, result; tau_oil=4260, Delta_t=10)
#    delta_oil_ss = ss_top_oil_rise(branch, result)
#    delta_oil = delta_oil_ss # if we are at 1st iteration then assume starts from steady-state
#
#    if ("delta_oil" in keys(branch) && "delta_oil_ss" in keys(branch))
#        println("Updating oil temperature")
#        delta_oil_prev = branch["delta_oil"]
#        delta_oil_ss_prev = branch["delta_oil_ss"] 
#
#
#        # trapezoidal integration
#        tau = 2*tau_oil/Delta_t
#        delta_oil = (delta_oil_ss + delta_oil_ss_prev)/(1 + tau) - delta_oil_prev*(1 - tau)/(1 + tau)
#    else
#        println("Setting initial oil temperature")
#    end
#
#   branch["delta_oil_ss"] = delta_oil_ss 
#   branch["delta_oil"] = delta_oil
#end
#
#""
#function update_top_oil_rise(branch, net)
#    k = "$(branch["index"])"
#    # update top-oil rise for the network
#    net["branch"][k]["delta_oil"] = branch["delta_oil"]
#    net["branch"][k]["delta_oil_ss"] = branch["delta_oil_ss"]
#end

#""
#function ss_top_oil_rise(branch, result; delta_rated=75)
#    if !branch["transformer"]
#        return 0
#    end
#        
#    i = branch["index"]
#    bs = result["solution"]["branch"]["$i"]
#    S = sqrt(bs["pf"]^2 + bs["qf"]^2)
#    K = S/branch["rate_a"] # calculate the loading
#
#    @printf "S: %0.3f, Smax: %0.3f\n" S branch["rate_a"]
#    # this assumes that no-load transformer losses are very small
#    # 75 = top oil temp rise at rated power
#    # 30 = ambient temperature
#    return delta_rated*K^2
#end

# i is index of the (transformer) branch
# fi is index of the "from" branch terminal
function constraint_temperature_steady_state(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, rate_a, delta_oil_rated)
    p_fr = var(pm, n, c, :p, fi) # real power
    q_fr = var(pm, n, c, :q, fi) # reactive power
    delta_oil_ss = var(pm, n, :ross, i) # top-oil temperature rise
    @constraint(pm,model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)
end


#
# i is index of the (transformer) branch
# fi is index of the "from" branch terminal
#function constraint_temperature_state_initial(pm::GenericPowerModel, n::Int, i::Int, fi::Int, c::Int, delta_oil_init, tau, time_elapsed)
#    delta_oil = var(pm, n, :ro, i) # top-oil temperature rise
#    #@constraint(pm.model, se - energy == time_elapsed*(charge_eff*sc - sd/discharge_eff))
#    # delta_oil = (delta_oil_ss + delta_oil_ss_prev)/(1 + tau) - delta_oil_prev*(1 - tau)/(1 + tau)
#    # assume that transformer starts at equilibrium 
#    @constraint(pm,model, delta_oil == (delta_oil_ss + delta_oil_init)/(1 + tau) - delta_oil_init*(1 - tau)/(1 + tau))
#end

#function constraint_temperature_state(pm::genericpowermodel, n_1::int, n_2::int, i::int, charge_eff, discharge_eff, time_elapsed)
#    sc_2 = var(pm, n_2, :sc, i)
#    sd_2 = var(pm, n_2, :sd, i)
#    se_2 = var(pm, n_2, :se, i)
#    se_1 = var(pm, n_1, :se, i)
#    # delta_oil = (delta_oil_ss + delta_oil_ss_prev)/(1 + tau) - delta_oil_prev*(1 - tau)/(1 + tau)
#    @constraint(pm.model, se_2 - se_1 == time_elapsed*(charge_eff*sc_2 - sd_2/discharge_eff))
#end
#
#function constraint_temperature_complementarity(pm::genericpowermodel, n::int, i)
#    sc = var(pm, n, :sc, i)
#    sd = var(pm, n, :sd, i)
#    @constraint(pm.model, sc*sd == 0.0)
#end
#
#function constraint_temperature_loss(pm::genericpowermodel, n::int, i, bus, r, x, standby_loss)
#    vm = var(pm, n, pm.ccnd, :vm, bus)
#    ps = var(pm, n, pm.ccnd, :ps, i)
#    qs = var(pm, n, pm.ccnd, :qs, i)
#    sc = var(pm, n, :sc, i)
#    sd = var(pm, n, :sd, i)
#    @nlconstraint(pm.model, ps + (sd - sc) == standby_loss + r*(ps^2 + qs^2)/vm^2)
#end

