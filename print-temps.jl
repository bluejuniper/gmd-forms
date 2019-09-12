using Printf
#network_ids = sort(collect(keys(net["nw"])))
network_ids = ["1","2","3","4"]

for nw in network_ids
  for (k,b) in net["nw"][nw]["branch"]
    sb = output["result"]["solution"]["nw"][nw]["branch"][k]
    #s = output["result"]["solution"]["nw"][nw]["branch"][k]["topoil_rise_ss"] 
    @printf "%0.3f " sb["topoil_rise_ss"]
  end

  println()
end
    
