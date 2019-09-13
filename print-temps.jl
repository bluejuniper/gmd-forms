using Printf
network_ids = sort(collect(keys(net["nw"])))
#network_ids = ["1","2","3","4"]

vname = "topoil_rise_ss"
vname = "topoil_rise"
#vname = "hotspot_rise_ss"
#vname = "hotspot_rise"
#vname = "hotspot"

function print_temps(vname)
#println("variable: $vname")
#for (k,b) in net["nw"]["1"]["branch"]
#  if b["type"] != "xf"
#    continue
#  end
#  @printf  "%4s " k
#end

println()

for nw in network_ids
  for (k,b) in net["nw"][nw]["branch"]
      if b["type"] != "xf"
        continue
      end
    sb = output["result"]["solution"]["nw"][nw]["branch"][k]
    @printf "%4.1f " sb[vname]
  end

  println()
end
end
    
