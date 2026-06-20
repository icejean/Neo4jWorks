/*
 * Copyright (c) "Jean Ye"
 * ZhuHai Taxation Bureau, China [1793893070@qq.com]
 * Original algorithm implementation in Python by David Eisenstat, [https://stackoverflow.com/users/2144669/david-eisenstat]
 * Reference to: Chu-Liu Edmond's algorithm for Minimum Spanning Tree on Directed Graphs
 * [https://stackoverflow.com/questions/23988236/chu-liu-edmonds-algorithm-for-minimum-spanning-tree-on-directed-graphs]
 *
 * This file is an addition to Neo4j.
 *
 * Neo4j is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.neo4j.gds.arborescence;

import org.neo4j.gds.Algorithm;
import org.neo4j.gds.api.Graph;
import org.neo4j.gds.collections.ha.HugeDoubleArray;
import org.neo4j.gds.collections.ha.HugeLongArray;
import org.neo4j.gds.core.utils.progress.tasks.ProgressTracker;
import org.neo4j.gds.spanningtree.Arc;
import org.neo4j.gds.spanningtree.OrderArcs;
import org.neo4j.gds.spanningtree.SpanningTree;

import static org.neo4j.gds.Converters.longToIntConsumer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.Stack;
import java.util.function.DoubleUnaryOperator;
import org.neo4j.gds.spanningtree.PrimOperators;

/**
 * Sequential Single-Source minimum weight spanning arborescence algorithm (ZhuLiu/Edmond).
 * <p>
 * The algorithm computes the MST by traversing all nodes from a given
 * startNodeId for a directed graph. 
 * Set concurrency to 1 for the ZhuLiu algorithm, as the contraction/uncontraction operation 
 * will change the data, so that the data should be refresh between concurrent threads,
 * but the current implementation is single thread.
 * 
 */
public class ZhuLiuOut extends Algorithm<SpanningTree> {

	private Graph graph;
	private final DoubleUnaryOperator minMax;
	private final long startNodeId;

	public ZhuLiuOut(Graph graph, DoubleUnaryOperator minMax, long startNodeId, ProgressTracker progressTracker) {
		super(progressTracker);
		this.graph = graph;
		this.minMax = minMax;
		this.startNodeId = startNodeId;
	}

	@Override
	public SpanningTree compute() {
		// Now only int index is supported.
		long nodeCountLong = graph.nodeCount();
		if (nodeCountLong > Integer.MAX_VALUE) {
			throw new IllegalStateException("Graph too large: " + nodeCountLong + " nodes, maximum supported is " + Integer.MAX_VALUE);
		}
		int nodeCount = (int) nodeCountLong;
		// Initialized as a null sapnning tree.
		HugeLongArray parent = HugeLongArray.newArray(nodeCount);
		parent.fill(-1);
		HugeDoubleArray costToParent = HugeDoubleArray.newArray(nodeCount);
		costToParent.fill(0);		
		int effectiveNodeCount = 0;
		Map<Integer, Arc> arborescence = new HashMap<Integer, Arc>();
		OrderArcs comparator = new OrderArcs((minMax == PrimOperators.MAX_OPERATOR));

		//System.out.println("min:"+(minMax == PrimOperators.MIN_OPERATOR));
		
		// Need to consider logging progress later.
        progressTracker.beginSubTask();
        
		try {
			// Make sure the test graph is correctly passed in from junit test case.
			//System.out.println("Is undirected: " + graph.isUndirected());
			//System.out.println("Nodes: " + nodeCount);
			//System.out.println("Relationships: " + graph.relationshipCount());
			
			// Get a list of all arcs for applying the ZhuLiu algorithm
			ArrayList<Arc> arcs = new ArrayList<Arc>();
			// Retrieve all arcs, O.K..
			for (int i = 0; i < nodeCount; i++) {
				graph.forEachRelationship(i, 0.0D, longToIntConsumer((s, t, w) -> {
					//arcs.add(new Arc(s, t, w));
					// Reverse the arcs 
					arcs.add(new Arc(t, s, w));					
					// Must return true for lambda function.
					return true;
				}));
			}

			// Map recording which super node(cycle) a node belongs to.
			Map<Integer, Integer> quotient_map = new HashMap<Integer, Integer>();

			// O.K., the arcs are there, initialize the quotient_map, each node is a cycle of itself at the beginning.
			//System.out.println("Arcs:" + arcs.size());
			Iterator<Arc> it = arcs.iterator();
			while (it.hasNext()) {
				Arc arc = it.next();
				quotient_map.put((int)arc.s, (int)arc.s);
				//System.out.println(arc.s + "->" + arc.t + ":" + arc.w);
			}
			// There may be no out degree of the root node,  set it too.
			quotient_map.put((int)startNodeId, (int)startNodeId);
			
			// There're nodes has no out degree, no spanning arborescence of this graph
			if(quotient_map.size()<nodeCount) {
				progressTracker.logInfo("There're nodes has no out degree: "+ (nodeCount - quotient_map.size()));
		        progressTracker.endSubTask();
		        // A null spanning tree
				return new SpanningTree(startNodeId, nodeCount, 0, parent,costToParent::get,0);
			}
			
			//print_map("Quotient map:",quotient_map);

			// candidate arcs of the spanning arborescence.
			ArrayList<Arc> good_arcs = new ArrayList<Arc>();

			int itn = 1;     // count of iteration
			while (true) {
				// 1. First step of the ZhuLiu algorithm, get minimum arcs for the current graph
				//System.out.println("Iteration: " + itn);
				//print_map("Quotient map:",quotient_map);
				Map<Integer, Arc> min_arc_by_tail_rep = new HashMap<Integer, Arc>();
				Map<Integer, Integer> successor_rep = new HashMap<Integer, Integer>();
				it = arcs.iterator();
				while (it.hasNext()) {
					Arc arc = it.next();
					if ((int)arc.s == (int)startNodeId)
						continue;
					int tail_rep = quotient_map.get((int)arc.s);
					int head_rep = quotient_map.get((int)arc.t);
					if (tail_rep == head_rep)
						continue;
					if (!min_arc_by_tail_rep.containsKey(tail_rep)
						//	|| ((Arc) min_arc_by_tail_rep.get(tail_rep)).w > arc.w) {
						|| comparator.compare2((Arc) min_arc_by_tail_rep.get(tail_rep), arc)) {
						
						min_arc_by_tail_rep.put(tail_rep, arc);
						successor_rep.put(tail_rep, head_rep);
					}
				}

				// 2. Second step of the zhuLiu algorithm, find cycle in the current minimum arcs set
				ArrayList<Integer> cycle_reps = find_cycle(successor_rep, (int)startNodeId);

				// 4. The last step of the ZhuLiu algorithm, there's no cycle in the current minimum arcs set, iteration comes to it's end.
				if (cycle_reps.size() == 0) {
					// Add last minimum arcs to good arcs
					Iterator<Arc> itm = min_arc_by_tail_rep.values().iterator();
					while (itm.hasNext())
						good_arcs.add(itm.next());
					// get the spanning arborescence from good arcs
					arborescence = spanning_arborescence(good_arcs, (int)startNodeId);
					// break the iteration loop
					break;
				}

				// There's a cycle
				// 3. The third step of the ZhuLiu algorithm, represent the cycle as a super node.
				// Add arcs in the cycle to good_arcs
				for (int node : cycle_reps) {
					Arc arc = (Arc) min_arc_by_tail_rep.get(node);
					good_arcs.add(arc);
				}
				// Represent the super node (the cycle) with the node id of the first node
				int cycle_rep = cycle_reps.get(0);
				// update quotient_map, represents all nodes in a cycle with it's fist node's id(cycle id).
				Iterator<Integer> itq = quotient_map.keySet().iterator();
				while (itq.hasNext()) {
					int node = itq.next();
					int node_rep = quotient_map.get(node);
					if (cycle_reps.contains(node_rep))
						quotient_map.put(node, cycle_rep);
				}

				// Log the progress.
				progressTracker.logInfo("contraction iteration: "+ itn + " nodes: "+nodeCount);
				itn++;

			}

		} catch (Exception e) {
			// e.printStackTrace(); logged above
		}

		// Update parent from spanning arborescence generated.
		double totalCost = 0;
		if (minMax == PrimOperators.MIN_OPERATOR) {
			// minimum
		} else {
			// maximum
		}
		
		for(Arc arc : arborescence.values()) {
// 			System.out.println(arc.s+"->"+arc.t+":"+arc.w);
			parent.set(arc.s, arc.t);
			costToParent.set(arc.s, arc.w);
			totalCost = totalCost+arc.w;
			effectiveNodeCount++;			
		}
// 		System.out.println("\n");
		// Add root node to effectiveNodeCount
		if(arborescence.size()>0)
			effectiveNodeCount++;
		
		SpanningTree spanningTree = new SpanningTree(startNodeId, nodeCount, effectiveNodeCount, parent, costToParent::get, totalCost);

        progressTracker.endSubTask();
		return spanningTree;
	}

	// Find a cycle in the current minimum arcs set.
	private ArrayList<Integer> find_cycle(Map<Integer, Integer> successor, int startNodeId) {
		// Nodes visited already.
		Set<Integer> visited = new HashSet<Integer>();
		// When the target node is root, the loop of finding a cycle should be terminated.
		visited.add(startNodeId);
		//print_map("Successor:",successor);
		// Loop through all nodes.
		Iterator<Integer> it = successor.keySet().iterator();
		while (it.hasNext()) {
			int node = it.next();
			// A new path for each time start cycle finding from a new node.
			ArrayList<Integer> path = new ArrayList<Integer>();
			// Loop until a cycle is found or reach the root node(root node is added to visited at the beginning).
			while (!visited.contains(node)) {
				visited.add(node);
				path.add(node);
				node = successor.get(node);
			}
			// Find a circle, now node is the last node in a cycle
			if (path.contains(node)) {
				int index = path.indexOf(node);
				// from index to the end, including index, size()-1, excluding size().
				ArrayList<Integer> cycle = new ArrayList<Integer>(path.subList(index, path.size()));
				// return the circle
				return cycle;
			}
		}
		// No cycle is found, return an empty list.
		return new ArrayList<Integer>();
	}

	// Make out a spanning arborescence from the candidate arcs.
	private Map<Integer, Arc> spanning_arborescence(ArrayList<Arc> arcs, int startNodeId) {
		// Build a reverse tree map for depth first traverse.
		// The value of arcs to a target node is an ArrayList, as there may be multiple arcs target at the same node.
		Map<Integer, ArrayList<Arc>> arcs_by_head = new HashMap<Integer, ArrayList<Arc>>();
		for (Arc arc : arcs) {
			if ((int)arc.s == startNodeId)
				continue;
			int head = (int)arc.t;
			if (!arcs_by_head.containsKey(head)) {
				ArrayList<Arc> arcs_h = new ArrayList<Arc>();
				arcs_h.add(arc);
				arcs_by_head.put(head, arcs_h);
			} else {
				ArrayList<Arc> arcs_h = arcs_by_head.get(head);
				arcs_h.add(arc);
				arcs_by_head.put(head, arcs_h);
			}
		}
		// The arcs of the resulting spanning arborescence.
		Map<Integer, Arc> solution_arc_by_tail = new HashMap<Integer, Arc>();
		// Stack for depth first traverse, so no need of iteration programming. 
		Stack<Arc> stack = new Stack<Arc>();
		// Push arcs target to the root node at the beginning.
		ArrayList<Arc> arcs_h = arcs_by_head.get(startNodeId);
		if(arcs_h!=null)
			for (Arc arc : arcs_h)
				stack.push(arc);
		// Depth first traverse in the candidate graph from the root node.
		while (!stack.empty()) {
			// Pop an arc to deal.
			Arc arc = stack.pop();
			// If the source node is in the resulting arborescence, just skip the arc.
			// This means, delete the arc which making the cycle, thus breaking the cycle.
			// Depth first traverse make sure that the cycles is broken in the reverse sequence of making them
			// in the iteration of the compute() function, which makes the correct result.
			if (solution_arc_by_tail.containsKey((int)arc.s))
				continue;
			// Put this arc in the result set.
			solution_arc_by_tail.put((int)arc.s, arc);
			// Push all arcs target at the source node of this arc into stack.
			// This makes a depth first traverse.
			arcs_h = arcs_by_head.get((int)arc.s);
			// Not a leaf
			if (arcs_h!=null)
				for (Arc arc_t : arcs_h)
					stack.push(arc_t);
		}
		// The result.
		return solution_arc_by_tail;
	}

	// print the quotient map or successor map.
	private void print_map(String name, Map<Integer, Integer> map) {
// 		System.out.println(name);
		Iterator<Integer> keyit = map.keySet().iterator();
		while (keyit.hasNext()) {
			Integer key = (Integer) keyit.next();
			int value = (int) map.get(key);
			System.out.print(key + ":" + value);
			if (keyit.hasNext())
				System.out.print(", ");
			else
				System.out.print("\n");
		}
	}
	
}
