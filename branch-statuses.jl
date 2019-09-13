using Printf


branch_ids = sort(collect(keys(raw_net["branch"])))
network_ids = sort(collect(keys(results["solution"]["nw"])))

for k in branch_ids
  b = raw_net["branch"][k]
  s0 = b["br_status"]
  @printf "%3s: %d " k s0
  changed = false

  for nw in network_ids
        s = results["solution"]["nw"][nw]["branch"][k]["pf"]
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
