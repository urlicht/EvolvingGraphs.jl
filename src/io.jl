# input data from a text file with each row is of the form 
# i    j   [w]  timestamp

"""
Read the contents of the Evolving Graph format file into a 
EvolvingGraph type object. If info is true, only return information 
about the number of nodes, the number of edges and the number of timestamps.
"""
function egreader(filename, info::Bool = false)
    egfile = open(filename, "r")
    # Read the first line
    firstline = chomp(readline(egfile))
    tokens = split(firstline)
    if tokens[1] != "%%EvolvingGraph"
        throw(ParseError("Not a valid EvolvingGraph header"))
    end
    (object, nodetype, timetype) = map(lowercase, tokens[2:4])
    is_directed = object == "directed" ? true : false
    

    # skip all comments and empty lines
    ll = readline(egfile)
    while length(chomp(ll)) == 0 || (length(ll) > 0 && ll[1] == '%')
        ll = readline(egfile)
    end

    dd = map(x -> parse(Int, x), split(ll))
    if length(dd) < 3
        throw(ParseError(string("Could not read in EvolvingGraph dimensions from line: ", ll)))
    end
    edges = dd[1]
    nodes = dd[2]
    times = dd[3]

    if info
        return (nodes, edges, times)
    end
        
    if nodetype == "integer" && timetype == "integer"
        ilist = Array(Int, edges)
        jlist = Array(Int, edges)
        timestamps = Array(Int, edges)
        for i in 1:edges
            entries = split(readline(egfile))
            ilist[i] = parse(Int, entries[1])
            jlist[i] = parse(Int, entries[2])
            timestamps[i] = parse(Int, entries[3])
        end
        return EvolvingGraph(is_directed, ilist, jlist, timestamps) 
    end
    
end

function egread(filename, info::Bool =false)
    file = open(filename, "r")
    firstline = chomp(readline(file))
    tokens = split(firstline)
    if tokens[1] != "%%EvolvingGraph"
        throw(ParseError("Not a valid EvolvingGraph header"))
    end
    is_directed = tokens[2] == "directed" ? true : false
    
    # skip all comments and empty lines
    ll = readline(file)

    while (length(ll) > 0 && ll[1] == '%')
        ll = readline(file)
    end
    
    header = split(chomp(ll), ',')
  
    length(header) >= 3 || error("The length of header must be >= 3") 
    
                  
    evolving_graph = length(header) == 3 ? true : false

    ilist = Any[]
    jlist = Any[]
    timestamps = Any[]

    if evolving_graph
        entries = split(chomp(readline(file)), ',')
        while length(entries) == 3
            push!(ilist, entries[1])
            push!(jlist, entries[2])
            push!(timestamps, entries[3])
            entries = split(chomp(readline(file)), ',')
        end            
        g = EvolvingGraph(is_directed, ilist, jlist, timestamps)
    else
        attributesvec = Dict[]
        entries = split(chomp(readline(file)), ',')

        while length(entries) >= 4           
            push!(ilist, entries[1])
            push!(jlist, entries[2])
            push!(timestamps, entries[3])
            push!(attributesvec, Dict(zip(header[4:end], entries[4:end])))
            entries = split(chomp(readline(file)), ',')
        end
        
        # try parse nodes and timestamps as Integer.
        try 
            ilist = [parse(Int64, s) for s in ilist]
            jlist = [parse(Int64, s) for s in jlist]
        end

        try 
            timestamps = [parse(Int64, s) for s in timestamps]
        end
        
        g = AttributeEvolvingGraph(is_directed, ilist, jlist, timestamps, attributesvec)
    end
    g
end

