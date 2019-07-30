using JuMP, PowerModels

### Temperature constraints ###
# i is index of the (transformer) branch
# fi is index of the "from" branch terminal
function constraint_temperature_steady_state(pm::GenericPowerModel, n::Int, i::Int, fi, c::Int, rate_a, delta_oil_rated)

    # S = sqrt(bs["pf"]^2 + bs["qf"]^2)
    # K = S/(branch["rate_a"] * base_mva) #calculate the loading

    # # println("S: $S \nSmax: $(branch["rate_a"]) \n")

    # # Assumptions: no-load, transformer losses are very small 
    # # 75 = top oil temp rise at rated power
    # # 25 = ambient temperature

    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = PMs.var(pm, n, c, :p, fi) # real power
    q_fr = PMs.var(pm, n, c, :q, fi) # reactive power
    delta_oil_ss = PMs.var(pm, n, c, :ross, i) # top-oil temperature rise
    # JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)
    # ARGHHHH...Why doesn't the objective make the inequality tight???!!!
    JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated == p_fr^2 + q_fr^2)

    
    #...old
    #delta_oil_ss = var(pm, n, :ross, i) 
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
end

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

