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
package org.neo4j.gds.kspanningtree;

import org.neo4j.gds.Algorithm;
import org.neo4j.gds.api.Graph;
import org.neo4j.gds.collections.ha.HugeDoubleArray;
import org.neo4j.gds.collections.ha.HugeLongArray;
import org.neo4j.gds.core.utils.progress.tasks.ProgressTracker;
import org.neo4j.gds.spanningtree.Arc;
import org.neo4j.gds.spanningtree.OrderArcs;
import org.neo4j.gds.spanningtree.PrimOperators;
import org.neo4j.gds.spanningtree.Prim;
import org.neo4j.gds.spanningtree.SpanningTree;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import java.util.function.DoubleUnaryOperator;

/**
 * The algorithm computes the KMST by traversing all nodes from a given
 * startNodeId. It aggregates all transitions into a MinPriorityQueue and visits
 * each (unvisited) connected node by following only the cheapest transition and
 * adding it to a specialized form of undirected tree.
 * <p>
 * After calculating the MST the algorithm cuts the tree at its k weakest
 * relationships to form k spanning trees
 */
public class PrimK extends Algorithm<SpanningTree> {

	private Graph graph;
	private final DoubleUnaryOperator minMax;
	private final long startNodeId;
	private final long k;

	public PrimK(Graph graph, DoubleUnaryOperator minMax, long startNodeId, long k, ProgressTracker progressTracker) {
		super(progressTracker);
		this.graph = graph;
		this.minMax = minMax;
		this.startNodeId = startNodeId;
		this.k = k;
	}

	@Override
	// Get the k spanning from a given starting node.
	public SpanningTree compute() {
		progressTracker.beginSubTask("MyKSpanningTree");
		// Get the whole spanning tree with Prim algorithm first.
		Prim prim = new Prim(graph, minMax, startNodeId, progressTracker, getTerminationFlag());
		SpanningTree spanningTree = prim.compute();
		// Get the k spanning tree with Prim algorithm again.
		var outputTree = growApproach(spanningTree);
		progressTracker.endSubTask("MyKSpanningTree");
		return outputTree;
	}

	// Get the parent & weight array of a spanning tree
	private double init(HugeLongArray parent, HugeDoubleArray costToParent, SpanningTree spanningTree) {
		graph.forEachNode((nodeId) -> {
			parent.set(nodeId, spanningTree.parent(nodeId));
			costToParent.set(nodeId, spanningTree.costToParent(nodeId));
			return true;
		});
		return spanningTree.totalWeight();
	}

	// build the k spanning tree with Prim algo again, stop when the number of nodes is k.
	private SpanningTree growApproach(SpanningTree spanningTree) {	
		// Check the range of k
		if (spanningTree.effectiveNodeCount() < k || k <= 0) {
			return spanningTree;
		}

		HugeLongArray parent = HugeLongArray.newArray(graph.nodeCount());
		HugeDoubleArray costToParent = HugeDoubleArray.newArray(graph.nodeCount());
		init(parent, costToParent, spanningTree);

		// TODO should be a huge array of Arc that support index of Long.
		Arc[] arcs = new Arc[(int) parent.size() - 1]; // arcs of the spanning tree
		Set<Long> heads = new HashSet<Long>(); // nodes of the k spanning tree

		// get all arcs of the spanning tree
		// TODO j should be long.
		int j = 0;
		for (long i = 0; i < parent.size(); i++) {
			// Node's parent
			long p = parent.get(i);
			// Root of spanning tree, skip
			if (p == -1) {
				continue;
			}
			arcs[j] = new Arc(p, i, costToParent.get(i));
			// Print for debugging.
			// System.out.println(p+"<-"+i+":"+costToParent.get(i));
			j++;
		}

		// Sort arcs for building a k spanning tree
		// There'll be null pointer exception sometimes, maybe caused by other 
		// concurrent threads
		// that runs before the previous code block of this thread, so catch it.
		// It's O.K. after catching the exception.
		try {
			boolean maxQueue = minMax == PrimOperators.MAX_OPERATOR;
			//System.out.println("min:"+(minMax == PrimOperators.MIN_OPERATOR));
			// TODO should be a huge array of Arc that support index of Long.
			Arrays.sort(arcs, 0, (int) parent.size() - 1, new OrderArcs(maxQueue));
		} catch (Exception e) {
			// e.printStackTrace();
		}

		// build the k spanning tree with Prim algo again, stop when the number of nodes is k.
		double totalCost = 0;
		heads.add(startNodeId);
		for (long n = 1; n < k; n++) {
			// TODO should be a huge array of Arc that support index of Long.
			for (int i = 0; i < parent.size() - 1; i++) {
				if (heads.contains(arcs[i].s) && (!heads.contains(arcs[i].t))) {
					heads.add(arcs[i].t);
					totalCost += arcs[i].w;
					break;
				}
			}
		}

		// remove other nodes doesn't belongs to the k spanning tree
		for (long i = 0; i < parent.size(); i++)
			if (!heads.contains(i)) {
				parent.set(i, -1);
				costToParent.set(i, 0);
			}

		// build the result k spanning tree
		SpanningTree KspanningTree = new SpanningTree(startNodeId, parent.size(), k, parent,
				costToParent::get, totalCost);

		// Print for debugging
		/*
		if (minMax == PrimOperators.MIN_OPERATOR)
			System.out.println("Result " + k + " min spanning tree:");
		else
			System.out.println("Result " + k + " max spanning tree:");
		for (long i = 0; i < parent.size(); i++) {
			System.out.println(i + ":" + parent.get(i) + "");
		}
		System.out.println();
		*/

		return KspanningTree;

	}

}
