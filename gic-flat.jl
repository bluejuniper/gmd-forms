using JSON, DataFrames, CSV, Ipopt, PowerModels, PowerModelsGMD, JuMP

 function run_ac_gic_flat(file, solver; kwargs...)
    return run_generic_model(file, PowerModelsGMD.ACPPowerModel, solver, post_gic_flat; solution_builder = PowerModelsGMD.get_gmd_solution, kwargs...)
end

function run_gic_opf_flat(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gic_flat; solution_builder = PowerModelsGMD.get_gmd_solution, kwargs...)
end


function post_gic_flat{T}(pm::GenericPowerModel{T}; kwargs...)
    PowerModelsGMD.variable_dc_voltage(pm)
    PowerModelsGMD.variable_dc_line_flow(pm)
    
    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
        PowerModelsGMD.constraint_dc_kcl_shunt(pm, i)
    end
    
    #for i in ids(pm, :gmd_branch)
    #    PowerModelsGMD.constraint_dc_ohms(pm, i)
    #end
end

path = "data/tx2000.json"
path = "data/b4gic.m"

path = "data/eastern-fixed.json"
opath ="data/eastern-fixed-results.json"

#path = "data/northeast-fixed.json"
#opath ="data/northeast-fixed-results.json"

#path = "data/northeast.json"
#path = "data/isone.json"

println("Start loading $path")
#net = PowerModels.parse_file(path)
h = open(path)
net = JSON.parse(h)
close(h)
println("Done loading $path")

println("Start solving $path")
ipopt_solver = IpoptSolver()
setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("line_flows" => true))
result = run_ac_gic_flat(net, ipopt_solver; setting=setting)
println("Done solving $path")

println("Start writing $opath")
h = open(opath, "w")
JSON.print(h, result)
close(h)
println("Done writing $opath")
