set NODES;
set EDGES within NODES cross NODES;
set DIRECTED_EDGES = EDGES union setof{(i,j) in EDGES} (j,i);

param nTravellers >0, integer;
param startNodes{1..nTravellers} symbolic in NODES;
param endNodes{1..nTravellers} symbolic in NODES;
param maxTicks >0, integer;


var useEdge{1..nTravellers, 1..maxTicks, DIRECTED_EDGES} binary; # 1 if and only if the edge is used at t by p in its shortest path

# must use exactly one edge from startNode[p] at t=1 to any j 
subject to validStart{p in 1..nTravellers}: sum{(i,j) in DIRECTED_EDGES: i = startNodes[p]} useEdge[p,1, i, j] = 1;

# when, in a path, n travellers enter a node at time t, exactly n travellers must exit the same node at time t+1. 
subject to balance{
		# for each traveller path p
		p in 1..nTravellers, 
		# for each time t
		t in 1..maxTicks,
		# for each node k 
		k in NODES:
			# such that (t is 1 implies that k is not startNode) and (t is not 1 implies that k is not endNode) and (t is not last tick)
			(t!=1 || k!=startNodes[p]) && (t==1 || k!=endNodes[p]) && t!=maxTicks
	# the sum of the usages of the edges that end on k at time t must be equal to the sum of the edges that start from k at t 			
	}: sum{(i, k) in DIRECTED_EDGES} useEdge[p,t,i,k] = sum{(k, j) in DIRECTED_EDGES} useEdge[p,t+1, k, j];
	

# the two paths cannot use edges that end up on the same node at the same time
subject to doNotEndUpOnSameNode{(k,t) in NODES cross (1..maxTicks)}: # for each node and time (k,t):
	# the sum for each path of (the sum of usages of edges that end on k in t) must not be greater than 1
	sum{p in 1..nTravellers} sum{(i,k) in DIRECTED_EDGES} useEdge[p,t,i,k] <= 1;

# if a path uses a edge from i to j in time t, the other paths cannot use a edge from j to i in same time t
subject to doNotUseSameEdgeReversed{p in 1..nTravellers, t in 1..maxTicks, (i,j) in DIRECTED_EDGES}:
	useEdge[p, t, i, j] + sum{op in 1..nTravellers: op!=p} useEdge[op, t, j, i] <= 1;


# minimize the sum of the lengths of the n paths
#   i.e. minimize the sum of the 4-dimensional table
minimize pathTotLen: sum{p in 1..nTravellers} sum{t in 1..maxTicks} sum {(i,j) in DIRECTED_EDGES} useEdge[p,t,i,j];