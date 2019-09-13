using Printf

function print_branches(vname, net)
  println("variable: $vname")

  branch_ids = sort(collect([b["index"] for b in values(raw_net["branch"])]))
  network_ids = sort(collect(keys(results["solution"]["nw"])))
  
  for i in branch_ids
    b = raw_net["branch"]["$i"]
    s0 = b["br_status"]
    @printf "%3d: %10s %d" i b["type"] s0
    changed = false
  
    for nw in network_ids
          x = results["solution"]["nw"][nw]["branch"]["$i"][vname]
          @printf " %.2f" x
    end

    println()
  end
end
    
