g = random_evolving_graph(3, 4)
g1 = aggregated_graph(g)
@test num_nodes(g1) == 3

g2 = evolving_graph(String, String)
add_edge!(g2, "a", "b", "t1")
add_edge!(g2, "b", "c", "t1")
add_edge!(g2, "c", "d", "t2")
add_edge!(g2, "a", "b", "t2")

g3 = aggregated_graph(g2)
@test num_nodes(g3) == 4
@test num_edges(g3) == 3

g4 = random_time_graph(3, 4)
aggregated_graph(g4)

