using Printf


branch_ids = sort(collect([b["index"] for b in values(raw_net["branch"])]))
network_ids = sort(collect(keys(results["solution"]["nw"])))

for i in branch_ids
  b = raw_net["branch"]["$i"]
  s0 = b["br_status"]
  @printf "%3d: %d " i s0
  changed = false

  for nw in network_ids
        s = results["solution"]["nw"][nw]["branch"]["$i"]["pf"]
        @printf " %.2f" s

        if s0 == 1 && abs(s) < 0.01
            changed = true
        end
  end
 
  if changed
      print(" *")
  end
  println()
end
