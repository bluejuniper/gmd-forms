using Ipopt, PowerModels, PowerModelsGMD

""
function run_gic_opf_ts(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gic_opf_ts; multinetwork=true, kwargs...)
end

""
function post_gic_opf_ts(pm::GenericPowerModel)
    for (n, network) in nws(pm)
        PowerModels.variable_voltage(pm, nw=n)
        PowerModelsGMD.variable_dc_voltage(pm, nw=n) # OK
        PowerModelsGMD.variable_dc_current_mag(pm, nw=n) # OK
        PowerModelsGMD.variable_qloss(pm, nw=n) # OK
        PowerModels.variable_generation(pm, nw=n)
        PowerModels.variable_branch_flow(pm, nw=n)
        PowerModels.variable_dcline_flow(pm, nw=n)
        PowerModelsGMD.variable_dc_line_flow(pm)

        PowerModels.constraint_voltage(pm, nw=n)

        for i in ids(pm, :ref_buses, nw=n)
            PowerModels.constraint_theta_ref(pm, i, nw=n)
        end

        for i in ids(pm, :bus, nw=n)
            # TODO: see if I can use shunt_gic instead
            PowerModelsGMD.constraint_kcl_gic(pm, i, nw=n) # OK
        end

        for i in ids(pm, :branch, nw=n)
            PowerModelsGMD.constraint_dc_current_mag(pm, i, nw=n) # OK
            PowerModelsGMD.constraint_qloss_vnom(pm, i, nw=n) # OK

            PowerModels.constraint_ohms_yt_from(pm, i, nw=n)
            PowerModels.constraint_ohms_yt_to(pm, i, nw=n)

            PowerModels.constraint_voltage_angle_difference(pm, i, nw=n)

            PowerModels.constraint_thermal_limit_from(pm, i, nw=n)
            PowerModels.constraint_thermal_limit_to(pm, i, nw=n)
        end

        ### DC network constraints ###
        for i in ids(pm, :gmd_bus)
            constraint_dc_kcl_shunt(pm, i, nw=n) # OK
        end

        for i in ids(pm, :gmd_branch)
            constraint_dc_ohms(pm, i, nw=n) # OK
        end

        for i in ids(pm, :dcline, nw=n)
            PowerModels.constraint_dcline(pm, i, nw=n)
        end
    end

    PowerModelsGMD.objective_gic_min_fuel(pm)
end


wf_path = "data/b4gic-gmd-wf.json"
h = open(wf_path)
wf_data = JSON.parse(h)
close(h)

t = wf_data["time"]
waveforms = wf_data["waveforms"]
n = length(t)

path = "data/b4gic.m"
raw_net = PowerModels.parse_file(path)
# fix an error in the data
raw_net["name"] = "b4gic"
raw_net["branch"]["2"]["transformer"] = false
@printf "Running model %s\n" raw_net["name"]

ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
results = []

mn = Dict{String,Any}(
    "name" => "$(raw_net["name"])_ts",
    "multinetwork" => true,
    "per_unit" => raw_net["per_unit"],
    "baseMVA" => raw_net["baseMVA"],
    "nw" => Dict{String,Any}()
)

ni = 1 # network index
for i in 1:10:n
    @printf "\n\n########## Time: %0.3f ##########\n" t[i]
    net = deepcopy(raw_net)

    # update the vs values
    for (k,wf) in waveforms
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        net[otype][k][field] = wf["values"][i]
    end

    delete!(net, "multinetwork")
    delete!(net, "per_unit")
    delete!(net, "baseMVA")
    mn["nw"]["$ni"] = net

    ni += 1
end

run_gic_opf_ts(mn, PowerModelsGMD.ACPPowerModel, ipopt_solver)


#outfile = string("data/", net["name"], "_result.json")
#println("\nSaving results to $outfile")
#f = open(outfile,"w")
#JSON.print(f,results)
#close(f)    
 




