# the show function 

function show(io::IO, g::EvolvingGraph)
    title = is_directed(g) ? "Directed EvolvingGraph" : "Undirected EvolvingGraph"
    print(io, "$(title) ($(num_nodes(g)) nodes, $(num_edges(g)) edges, $(num_timestamps(g)) timestamps)")
end

function show(io::IO, g::IntEvolvingGraph)
    title = is_directed(g) ? "Directed IntEvolvingGraph" : "Undirected IntEvolvingGraph"
    print(io, "$(title) ($(num_nodes(g)) nodes, $(num_edges(g)) edges, $(num_timestamps(g)) timestamps)")
end

function show(io::IO, g::TimeGraph)
    title = is_directed(g) ? "Directed TimeGraph" : "Undirected TimeGraph"
    print(io, "$(title) ($(num_nodes(g)) nodes, $(num_edges(g)) edges)")
end
