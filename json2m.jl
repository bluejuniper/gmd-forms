using GZip, JSON, Ipopt, PowerModelsGMD, PowerModels, JuMP, DelimitedFiles
include("powermodelsio.jl")

println("Start loading json")
path = "data/rts-gmlc-gic.json"
opath = "data/rts-gmlc-gic-results.json"



println("Start loading $path")
if endswith(path, ".m") || endswith(path, ".raw")
    net = PowerModels.parse_file(path)
elseif endswith(path, ".gz")
    h = GZip.open(path)
    net = JSON.parse(h)
    close(h)
elseif endswith(path, ".json")
    h = open(path)
    net = JSON.parse(h)
    close(h)
    println("Converting to per-unit")
end
println("Done loading $path")

net["storage"] = Dict()
PowerModels.make_per_unit!(net)

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
println("Start solving")
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
# result = run_gmd(net, ipopt_solver; setting=setting)
result = run_ac_gmd_opf_decoupled(net, ipopt_solver; setting=setting)

for (k,b) in net["bus"]
	delete!(b, "gmd_bus")
	delete!(b, "gmd_neu_bus")
	delete!(b, "sid")
	delete!(b, "type")
	delete!(b, "nid")
	delete!(b, "sub")
	delete!(b, "gmd_gs")
	delete!(b, "gmd_k")
	delete!(b, "gmd_baseMVA")
end

for (k,b) in net["branch"]
	delete!(b, "f_breaker_damaged")
	delete!(b, "t_breaker_damaged")
	delete!(b, "len_km")
	delete!(b, "br_rdc")
	delete!(b, "gmd_vdc")
	delete!(b, "gmd_R_ohms")
	delete!(b, "gmd_r_Ohms")
	# delete!(b, "transformer")
	delete!(b, "dist_e_km")
	delete!(b, "dist_n_km")
	delete!(b, "name")
	# delete!(b, "sub")
	delete!(b, "gmd_br")
	delete!(b, "gmd_r_actual")
	delete!(b, "data")
	delete!(b, "gmd_BaseMVA")
	delete!(b, "gmd_baseMVA")
	# delete!(b, "gmd_k")
	delete!(b, "nid")
	delete!(b, "sub")
	delete!(b, "gmd_gs")

	if !("config" in keys(b))
		b["config"] = "none"
	end

	if !("gmd_br_hi" in keys(b))
		b["gmd_br_hi"] = -1
	end

	if !("gmd_br_lo" in keys(b)) || b["gmd_br_lo"] === nothing
		b["gmd_br_lo"] = -1
	end

	if !("gmd_br_series" in keys(b))
		b["gmd_br_series"] = -1
	end

	if !("gmd_br_common" in keys(b))
		b["gmd_br_common"] = -1
	end

	if !("gmd_k" in keys(b))
		b["gmd_k"] = -1
	end
end

for (k,g) in net["gen"]
	delete!(g, "name")
	delete!(g, "type")
end

for (k,b) in net["gmd_bus"]
	delete!(b, "parent_name")
end

for(k,d) in net["load"]
	delete!(d, "nid")
	delete!(d, "sid")
	delete!(d, "bus_i")
	delete!(d, "name")
	delete!(d, "base_kv")
	delete!(d, "type")
end

for (k,b) in net["gmd_branch"]
	delete!(b, "parent_name")
	delete!(b, "name")
	delete!(b, "len_km")
	delete!(b, "data")
end

delete!(net, "sub")
delete!(net, "waveforms")

# for (k,s) in net["sub"]
# 	delete!("dc_bus_Factory")
# 	s["g"] = 1/s["gmd_rs_Ohms"]
# 	delete!("sid")
# 	delete!("dc_bus_Factory")
# 	delete!("gmd_bus")
# 	delete!("type")
# end


delete!(net, "hash")
delete!(net, "gmd_e_field_mag")
delete!(net, "gmd_e_field_dir")
delete!(net, "source_path")
delete!(net, "timestamp")
delete!(net, "version")

net["name"] = "rts_gmlc_gic"


io = open("data/rts_gmlc_gic.m", "w")
PowerModels.export_matpower(io, net)
close(io)