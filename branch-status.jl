using Printf

for (k,b) in net["branch"]
    s = result["solution"]["branch"][k]["br_status"]
    s0 = b["br_status"]
    # println("$k: $s0 -> $s")
    @printf "%3s: %d -> %.2f" k s0 s

    if s0 == 1 && s < 0.5
        print(" *")
    end

    println()
end