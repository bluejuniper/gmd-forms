using DataFrames, DelimitedFiles, Printf

function update_gmd_status!(net)
    for gb in values(net["gmd_bus"])
        i = gb["parent_index"]
    
        if gb["parent_type"] == "sub"
            continue
        end
    
        b = net["bus"]["$i"]
    
        if b["bus_type"] == 4
            gb["status"] = 0
        end
    end
    
    for gbr in values(net["gmd_branch"])
        i = gbr["parent_index"] 
        br = net["branch"]["$i"]
    
        if br["br_status"] == 0
            gbr["br_status"] = 0
        end
    end
end

function printdict(x; drop=["index","bus_i"])
    drop_set = Set(drop)

    for (k,y) in x
        if k in drop_set
            continue
        end

        println("$k: $y")
    end
end

function todf(case, table_name; result=nothing)
    df = DataFrame()
    table = case[table_name]

    if result !== nothing
        soln_table = result["solution"][table_name]
    end
    
    cols = collect(keys(table))
    
    df[:index] = cols

    for k in keys(first(values(table)))
        #col = [x[k] for x in values(table)]
        col = []

        for x in values(table)
            if k in keys(x)
                push!(col, x[k])
            else
                push!(col, nothing)
            end
        end

        df[Symbol(k)] = col 
    end 
    
    if solution !== nothing
        for k in keys(first(values(soln_table)))
            col = [x[k] for x in values(soln_table)]

            df[Symbol(k)] = col 
        end 
    end
    
    return df
end

# output["case"]["nw"]["1"]["branch"]["1"]
# output["result"]["solution"]["nw"]["1"]["branch"]["1"]
function ts_output_to_df(output::Dict{Any,Any}, table_name, n; gmd_table_name=nothing)
    df = DataFrame()
    table = output["case"]["nw"]["$n"][table_name]
    soln_table = output["result"]["solution"]["nw"]["$n"][table_name]
    gmd_table = output["case"]["nw"]["$n"][gmd_table_name]
    gmd_soln_table = output["result"]["solution"]["nw"]["$n"][gmd_table_name]

    # not necc. unique!
    gmd_lookup = Dict(("$(x["parent_index"])",x) for x in values(gmd_table))
    
    cols = sort(collect(keys(table)))
    okeys = cols
    
    df[:index] = cols

    for f in keys(first(values(gmd_soln_table))) # iterate over solution fields
        if f == "source_id"
            continue
        end

        col = []

        for k in okeys
            if !(k in keys(gmd_lookup))
                push!(col, "null")
                continue
            end

            g = gmd_lookup[k]
            x = gmd_soln_table["$(g["index"])"]

            if f in keys(x)
                push!(col, x[f])
            else
                push!(col, "null")
            end
        end

        df[Symbol(f)] = col 
    end     

    for f in keys(first(values(gmd_table))) # iterate over solution fields
        if f == "source_id"
            continue
        end

        col = []

        for k in okeys
            if !(k in keys(gmd_lookup))
                push!(col, "null")
                continue
            end

            x = gmd_lookup[k]

            if f in keys(x)
                push!(col, x[f])
            else
                push!(col, "null")
            end
        end

        df[Symbol(f)] = col 
    end 


    for f in keys(first(values(soln_table))) # iterate over solution fields
        if f == "source_id"
            continue
        end

        col = []
        
        for k in okeys
            x = soln_table[k]

            if f in keys(x)
                push!(col, x[f])
            else
                push!(col, "")
            end
        end

        df[Symbol(f)] = col 
    end 

    for f in keys(first(values(table))) # iterate over fie
        #col = [x[k] for x in values(table)]
        if f == "source_id"
            continue
        end

        col = []
        

        for k in okeys # iterate over objects
            x = table[k]

            if f in keys(x)
                push!(col, x[f])
            else
                push!(col, nothing)
            end
        end

        df[Symbol(f)] = col 
    end 
    
   
    return df
end

function ts_output_to_csv(io::IOStream, output, table_name, n)
    df = ts_output_to_df(output, table_name, n)
    writedlm(io,names(df), ",")
    writedlm(io, eachrow(df), ",")
end

function ts_output_to_csv(file::String, output, table_name, n; gmd_table_name=nothing)
    io = open(file, "w")
    df = ts_output_to_df(output, table_name, n; gmd_table_name=gmd_table_name)
    println(io, join(names(df), ","))
    writedlm(io, eachrow(df), ",")
    close(io)
end

function ts_output_to_csv(prefix::String, output::Dict{Any,Any}, table_name; gmd_table_name=nothing)
    nws = sort([parse(Int, n) for n in keys(output["case"]["nw"])])
    for n in nws
        file = @sprintf "%s_%s_output_%d.csv" prefix table_name n
        ts_output_to_csv(file, output, table_name, n; gmd_table_name=gmd_table_name)
    end
end

function ts_output_to_aux(io::IOStream, output::Dict{Any,Any}, n)
    df = DataFrame()
    branches = output["case"]["nw"]["$n"]["branch"]
    soln_branches = output["result"]["solution"]["nw"]["$n"]["branch"]

    println(io, "Branch (BusNumFrom,BusNumTo,Circuit,Status)\n{")

    for (k, br) in branches
        bf = br["f_bus"]
        bt = br["t_bus"]
        ckt = br["ckt"]
        brs = soln_branches[k]

        status = "Closed"

        if br["br_status"] == 0 || max(abs(brs["pf"]), abs(brs["pt"])) < 1e-3
            status = "Open"
        end

        println(io, "\t$bf\t$bt\t\"$ckt\"\t\"$status\"")
    end

    println(io, "}")
end

function ts_base_to_aux(io::IOStream, output::Dict{Any,Any}, n)
    df = DataFrame()
    branches = output["case"]["nw"]["$n"]["branch"]

    println(io, "Branch (BusNumFrom,BusNumTo,Circuit,Status)\n{")

    for (k, br) in branches
        bf = br["f_bus"]
        bt = br["t_bus"]
        ckt = br["ckt"]

        status = "Closed"

        if br["br_status"] == 0 
            status = "Open"
        end

        println(io, "\t$bf\t$bt\t\"$ckt\"\t\"$status\"")
    end

    println(io, "}")
end

function ts_base_to_aux(file::String, output::Dict{Any,Any}, n)
    io = open(file, "w")
    ts_base_to_aux(io, output, n)
    close(io)
end

function ts_output_to_aux(file::String, output::Dict{Any,Any}, n)
    io = open(file, "w")
    ts_output_to_aux(io, output, n)
    close(io)
end

function ts_output_to_aux(prefix::String, output::Dict{Any,Any})
    basefile = @sprintf "%s%d.aux" prefix 0
    ts_base_to_aux(basefile, output, 1)

    nws = sort([parse(Int, n) for n in keys(output["case"]["nw"])])   
    for n in nws
        file = @sprintf "%s%d.aux" prefix n
        ts_output_to_aux(file, output, n)
    end
end