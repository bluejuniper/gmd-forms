using DataFrames, DelimitedFiles

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
function ts_output_to_df(output::Dict{Any,Any}, table_name; n=1)
    df = DataFrame()
    table = output["case"]["nw"]["$n"][table_name]
    soln_table = output["result"]["solution"]["nw"]["$n"][table_name]
    
    cols = collect(keys(table))
    
    df[:index] = cols

    for k in keys(first(values(table)))
        #col = [x[k] for x in values(table)]
        if k == "source_id"
            continue
        end

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
    
    for k in keys(first(values(soln_table)))
        col = [x[k] for x in values(soln_table)]

        df[Symbol(k)] = col 
    end 
    
    return df
end

function ts_output_to_df(io::IOStream, output, table_name; n=1)
    df = ts_output_to_df(output, table_name; n=n)
    writedlm(io,names(df), ",")
    writedlm(io, eachrow(df), ",")
end

function ts_output_to_df(file::String, output, table_name; n=1)
    io = open(file, "w")
    df = ts_output_to_df(output, table_name; n=n)
    println(io, join(names(df), ","))
    writedlm(io, eachrow(df), ",")
    close(io)
end

function ts_output_to_aux(io::IOStream, output::Dict{Any,Any}; n=1)
    df = DataFrame()
    branches = output["case"]["nw"]["$n"]["branch"]
    soln_branches = output["result"]["solution"]["nw"]["$n"]["branch"]

    println(io, "Branch (BusNumFrom,BusNumTo,Circuit,Status)\n{")

    for (k, br) in branches
        bf = br["f_bus"]
        bt = br["t_bus"]
        ckt = br["ckt"]
        println(io, "$bf\t$bt\t\"$ckt\"")
    end

    println(io, "}")
end

function ts_output_to_aux(file::String, output; n=1)
    io = open(file, "w")
    df = ts_output_to_aux(output; n=n)
    println(io, join(names(df), ","))
    writedlm(io, eachrow(df), ",")
    close(io)
end