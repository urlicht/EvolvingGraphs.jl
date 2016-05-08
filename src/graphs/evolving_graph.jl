
####################################################
#
# EvolvingGraph type
#
#####################################################

type EvolvingGraph{V, E, T} <: AbstractEvolvingGraph{V, E, T}
    is_directed::Bool
    nodes::Vector{V}                 # a vector of nodes
    edges::Vector{E}                 # a vector of edges
    timestamps::Vector{T}        # a vector of timestamps
    indexof::Dict{Any, Int}        # a dictionary storing index for each node
end


"""
    evolving_graph([node_type, time_type[, is_directed = true])

Initialize an evolving graph where the nodes are of type `node_type` and 
the timestamps are of type `time_type`.
"""
evolving_graph{V,T}(::Type{V}, ::Type{T} ;is_directed::Bool = true) = 
      EvolvingGraph(is_directed, Node{V}[], TimeEdge{Node{V}, T}[], T[], Dict{Any, Int}())

"""
    evolving_graph([is_directed = true])

Initialize an evolving graph with integer nodes and timestamps.
"""
evolving_graph(;is_directed::Bool = true) = 
       evolving_graph(Int, Int, is_directed = is_directed)

"""
    evolving_graph(ils, jls, timestamps[, is_directed = true]) 
Generate an evolving graph from three input vectors: ils, jls and timestamps, such that
the ith entry `(ils[i], jls[i] and timestamps[i])` is an edge from `ils[i]` to `jls[i]` at timestamp
`timestamp[i]`.
"""
function evolving_graph{V,T}(ils::Vector{V},
                             jls::Vector{V},
                             timestamps::Vector{T};
                             is_directed::Bool = true)
    n = length(ils)
    n == length(jls) == length(timestamps)|| 
            error("3 input vectors must have the same length.")
    g = evolving_graph(V, T, is_directed = is_directed)
    
    for i = 1:n
        v1 = add_node!(g, ils[i])
        v2 = add_node!(g, jls[i])
        add_edge!(g, TimeEdge(v1, v2, timestamps[i]))
    end
    g
end

deepcopy(g::EvolvingGraph) = EvolvingGraph(is_directed(g), 
                                           deepcopy(g.nodes),
                                           deepcopy(g.edges), 
                                           deepcopy(g.timestamps))

"""
    undirected!(g)

Change a directed evolving graph g to an undirected evolving graph.
"""
undirected!(g::EvolvingGraph) = ( g.is_directed = false ; g)

"""
    undirected(g)

Make a copy of g and change it to an undirected evolving graph.
"""
undirected(g::EvolvingGraph) = undirected!(deepcopy(g))
eltype{V, T}(g::EvolvingGraph{V, T}) = (V, T)

###### nodes ##############################################

"""
    has_node(g, v, t)

Return `true` if `(v,t)` is an active node of `g` and `false` otherwise.
"""
function has_node(g::EvolvingGraph, v, t)
    p = findin(g.timestamps , [t])
    es = g.edges[p]
    for e in es
        if !(has_node(e, v))
            return false
        end
    end
    return true
end

"""
    has_node(g, v)

Return `true` if  `v` is a node of `g`.
"""
has_node{V}(g::EvolvingGraph{V}, v::V) = v in g.nodes
function has_node(g::EvolvingGraph, v)
    id = zero(Int)
    try 
        id = g.indexof[v]
    catch
        id = zero(Int)
    end
    return id != zero(Int)
end

"""
    nodes(g)

Return the nodes of the evolving graph `g`.
"""
nodes(g::EvolvingGraph) = g.nodes
num_nodes(g::EvolvingGraph) = length(nodes(g))

function timestamps(g::EvolvingGraph) 
    ts = unique(g.timestamps)
    return sort(ts)
end
num_timestamps(g::EvolvingGraph) = length(timestamps(g))


"""
    edges(g)

Return the edges of g in type TimeEdge.
"""
edges(g::EvolvingGraph) = g.edges


"""
    edges(g, t)

Return the edges of an evolving graph `g` at a given timestamp `t`.
"""
function edges(g::EvolvingGraph, t)
    inds = findin(g.timestamps, [t])
    if length(inds) == 0
        error("unknown timestamp $(t)")
    end
    return g.edges[inds]
end


"""
    num_edges(g)

Return the number of edges of an evolving graph `g`.
"""
num_edges(g::EvolvingGraph) = length(g.edges)


"""
    add_node!(g, v)

Add a node `v` to an evolving graph `g`.
"""
function add_node!{V}(g::EvolvingGraph{V}, v::V) 
    push!(g.nodes, v)
    g.indexof[v.key] = length(g.nodes)
    v
end
function add_node!{V}(g::EvolvingGraph{V}, v) 
    id = zero(Int)
    try 
        id = g.indexof[v]
    catch
        id = zero(Int)
    end
    if id == zero(Int)
        v = make_node(g, v)
        return add_node!(g, v)
    else
        return Node(id, v)
    end
end

"""
    add_edge!(g, te)

Add a TimeEdge `te` to an evolving graph `g`.
"""
function add_edge!{V, E}(g::EvolvingGraph{V, E}, e::E)
    push!(g.edges, e)
    push!(g.timestamps, e.timestamp)
    if !(is_directed(g))
        push!(g.edges, rev(e))
        push!(g.timestamps, e.timestamp)
    end
    e
end

"""
    add_edge!(g, v1, v2, t)

Add an edge from `v1` to `v2` at time `t` to an evolving graph `g`.
"""
function add_edge!(g::EvolvingGraph, v1, v2, t)
    v1 = add_node!(g, v1)
    v2 = add_node!(g, v2)
    e = TimeEdge(v1, v2, t)
    if !(e in edges(g))
        add_edge!(g, e)
    end
    e
end

# short-cut for adding multiply edges
function add_edge!(g::EvolvingGraph, v1::Array, v2::Array, t)
    for j in v2
        for i in v1
            add_edge!(g, i, j, t)
        end
    end
    g
end

has_edge{V, E}(g::EvolvingGraph{V,E}, e::E) = e in edges(g)


function rm_edge!(g::EvolvingGraph, e::TimeEdge)
    id = findfirst(g.edges, e)
    id == 0 || error("$(e) is not in the graph.")

    splice!(g.edges, id)
    splice!(g.timestamps, id)
    g
end


"""
    matrix(g, t[, T = Bool])

Return an adjacency matrix representation of an evolving graph `g` at timestamp `t`.
`T` (optional) is the element type of the matrix.
"""
function matrix(g::EvolvingGraph, t, T::Type = Bool)
    n = num_nodes(g)
    es = edges(g, t)
    A = zeros(T, n, n)
    for e in es
        i = node_index(e.source)
        j = node_index(e.target)
        A[(j-1)*n + i] = one(T)
    end
    return A
end


"""
    spmatrix(g, t[, T = Bool])

Return a sparse adjacency matrix representation of an evolving graph
`g` at timestamp `t`. `T` (optional) is the element type of the matrix.
"""
function spmatrix(g::EvolvingGraph, t, T::Type = Bool)
    n = num_nodes(g)
    is = Int[]
    js = Int[]
    es = edges(g, t)
    for e in es
        i = node_index(e.source)
        j = node_index(e.target)
        push!(is, i)
        push!(js, j)
    end
    vs = ones(T, length(is))
    return sparse(is, js, vs, n, n)    
end
