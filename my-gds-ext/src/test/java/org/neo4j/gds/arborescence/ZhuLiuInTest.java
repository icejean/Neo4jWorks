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

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.neo4j.gds.Orientation;
import org.neo4j.gds.api.Graph;
import org.neo4j.gds.core.utils.progress.tasks.ProgressTracker;
import org.neo4j.gds.extension.GdlExtension;
import org.neo4j.gds.extension.GdlGraph;
import org.neo4j.gds.extension.IdFunction;
import org.neo4j.gds.extension.Inject;
import org.neo4j.gds.collections.ha.HugeLongArray;
import org.neo4j.gds.spanningtree.SpanningTree;

import static org.junit.jupiter.api.Assertions.assertEquals;


/**
 * Tests if ZhuLiu returns a valid tree for each node
 */
@GdlExtension
class ZhuLiuInTest {

    @GdlGraph(orientation = Orientation.NATURAL, idOffset = 0)
    private static final String DB_CYPHER =
        "CREATE" +
        "  (a:Node)" +
        ", (b:Node)" +
        ", (c:Node)" +
        ", (d:Node)" +
        ", (e:Node)" +

        ", (b)-[:TYPE {cost: 17.0}]->(a)" +
        ", (c)-[:TYPE {cost: 16.0}]->(a)" +
        ", (d)-[:TYPE {cost: 19.0}]->(a)" +
        ", (e)-[:TYPE {cost: 16.0}]->(a)" +
        ", (c)-[:TYPE {cost: 3.0}]->(b)" +
        ", (d)-[:TYPE {cost: 3.0}]->(b)" +
        ", (e)-[:TYPE {cost: 11.0}]->(b)" +
        ", (b)-[:TYPE {cost: 3.0}]->(c)" +
        ", (d)-[:TYPE {cost: 4.0}]->(c)" +
        ", (e)-[:TYPE {cost: 8.0}]->(c)" +
        ", (b)-[:TYPE {cost: 3.0}]->(d)" +
        ", (c)-[:TYPE {cost: 4.0}]->(d)" +
        ", (e)-[:TYPE {cost: 12.0}]->(d)" +
        ", (b)-[:TYPE {cost: 11.0}]->(e)" +        
        ", (c)-[:TYPE {cost: 8.0}]->(e)" +
        ", (d)-[:TYPE {cost: 12.0}]->(e)";

    private static int a, b, c, d, e;

    @Inject
    private Graph graph;

    @Inject
    private IdFunction idFunction;

    @BeforeEach
    void setUp() {
        a = (int) idFunction.of("a");
        b = (int) idFunction.of("b");
        c = (int) idFunction.of("c");
        d = (int) idFunction.of("d");
        e = (int) idFunction.of("e");
    }
    
    @Test
    void testMinimumFromA() {
    	SpanningTree mst = (new ZhuLiuIn(graph, PrimOperators.MIN_OPERATOR, a, ProgressTracker.NULL_TRACKER).compute());
    	HugeLongArray parent = mst.parentArray();
        assertEquals(5, mst.effectiveNodeCount());
        assertEquals(-1,parent.get(0));
        assertEquals(2,parent.get(1));
        assertEquals(0,parent.get(2));
        assertEquals(1,parent.get(3));
        assertEquals(2,parent.get(4));                
    }
    
    
    @Test
    void testMinimumFromB() {
    	SpanningTree mst = (new ZhuLiuIn(graph, PrimOperators.MIN_OPERATOR, b, ProgressTracker.NULL_TRACKER).compute());
    	HugeLongArray parent = mst.parentArray();
        assertEquals(0, mst.effectiveNodeCount());
        assertEquals(-1,parent.get(0));
        assertEquals(-1,parent.get(1));
        assertEquals(-1,parent.get(2));
        assertEquals(-1,parent.get(2));
        assertEquals(-1,parent.get(4));                    	
    }

    @Test
    void testMaximumFromA() {
    	SpanningTree mst = (new ZhuLiuIn(graph, PrimOperators.MAX_OPERATOR, a, ProgressTracker.NULL_TRACKER).compute());
    	HugeLongArray parent = mst.parentArray();        
    	assertEquals(5, mst.effectiveNodeCount());
        assertEquals(-1,parent.get(0));
        assertEquals(0,parent.get(1));
        assertEquals(0,parent.get(2));
        assertEquals(0,parent.get(2));
        assertEquals(0,parent.get(4));                    	
    }
    
    @Test
    void testMaximumFromB() {
    	SpanningTree mst = (new ZhuLiuIn(graph, PrimOperators.MAX_OPERATOR, b, ProgressTracker.NULL_TRACKER).compute());
    	HugeLongArray parent = mst.parentArray();            	
    	assertEquals(0, mst.effectiveNodeCount());
        assertEquals(-1,parent.get(0));
        assertEquals(-1,parent.get(1));
        assertEquals(-1,parent.get(2));
        assertEquals(-1,parent.get(2));
        assertEquals(-1,parent.get(4));                    	
    }  
      
}
