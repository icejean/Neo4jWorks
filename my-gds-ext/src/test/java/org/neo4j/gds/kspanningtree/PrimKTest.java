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


import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.neo4j.gds.Orientation;
import org.neo4j.gds.api.Graph;
import org.neo4j.gds.core.utils.progress.tasks.ProgressTracker;
import org.neo4j.gds.extension.GdlExtension;
import org.neo4j.gds.extension.GdlGraph;
import org.neo4j.gds.extension.IdFunction;
import org.neo4j.gds.extension.Inject;


import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Tests if MSTPrim returns a valid tree for each node
 *
 *         a                  a                  a
 *     1 /   \ 2            /  \                  \
 *      /     \            /    \                  \
 *     b --3-- c          b      c          b       c
 *     |       |  =min=>  |      |  =max=>  |       |
 *     4       5          |      |          |       |
 *     |       |          |      |          |       |
 *     d --6-- e          d      e          d-------e
 */

@GdlExtension
class PrimKTest {

    // setting the idOffset to 0 as there is dedicated testing for id offset
    @GdlGraph(orientation = Orientation.UNDIRECTED, idOffset = 0)
    private static final String DB_CYPHER =
    		"CREATE " +
    		"  (a:Node)" +
    		", (b:Node)" +
    		", (c:Node)" +
    		", (d:Node)" +
    		", (e:Node)" +

    		", (a)-[:TYPE {w: 1.0}]->(b)" +
    		", (a)-[:TYPE {w: 2.0}]->(c)" +
    		", (b)-[:TYPE {w: 3.0}]->(c)" +
    		", (b)-[:TYPE {w: 4.0}]->(d)" +
    		", (c)-[:TYPE {w: 5.0}]->(e)" +
    		", (d)-[:TYPE {w: 6.0}]->(e)";

    @Inject
    private Graph graph;

    @Inject
    private IdFunction idFunction;

    private int a, b, c, d, e;

    @BeforeEach
    void setUp() {
        a = (int) idFunction.of("a");
        b = (int) idFunction.of("b");
        c = (int) idFunction.of("c");
        d = (int) idFunction.of("d");
        e = (int) idFunction.of("e");
    }

    @Test
    void testMaximumKSpanningTree() {
        var spanningTree = new PrimK(graph, PrimOperators.MAX_OPERATOR, a, 4, ProgressTracker.NULL_TRACKER)
            .compute();
        long[] parent = spanningTree.parentArray().toArray();
        assertEquals(parent[a], -1);
        assertEquals(parent[b], -1);
        assertEquals(parent[c], 0);
        assertEquals(parent[d], 4);
        assertEquals(parent[e], 2);
    }

    @Test
    void testMinimumKSpanningTree() {
        var spanningTree = new PrimK(graph, PrimOperators.MIN_OPERATOR, a, 4, ProgressTracker.NULL_TRACKER)
            .compute();
        long[] parent = spanningTree.parentArray().toArray();
        assertEquals(parent[a], -1);
        assertEquals(parent[b], 0);
        assertEquals(parent[c], 0);
        assertEquals(parent[d], 1);
        assertEquals(parent[e], -1);
    }

}
