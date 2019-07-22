using DataFrames

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
