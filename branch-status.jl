using Printf

branch_ids = sort(collect([b["index"] for b in values(net["branch"])]))


for i in branch_ids
    b = net["branch"]["$i"]
    s = result["solution"]["branch"]["$i"]["br_status"]
    s0 = b["br_status"]
    # println("$k: $s0 -> $s")
    @printf "%3d: %d -> %0.1f" i s0 s

    if s0 == 1 && s < 0.5
        print(" *")
    end

    println()
end