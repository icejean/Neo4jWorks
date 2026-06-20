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
package org.neo4j.gds.paths.arborescence;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.neo4j.gds.BaseProcTest5x;
import org.neo4j.gds.GdsCypher;
import org.neo4j.gds.Orientation;
import org.neo4j.gds.catalog.GraphProjectProc;
import org.neo4j.gds.extension.Neo4jGraph;

import java.util.Iterator;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;


public class KArborescenceOutWriteProcTest extends BaseProcTest5x {

    private static String GRAPH_NAME = "graph";

    @Neo4jGraph
    private static final String DB_CYPHER =
    "CREATE" +
    "  (a:Node)" +
    ", (b:Node)" +
    ", (c:Node)" +
    ", (d:Node)" +
    ", (e:Node)" +
    ", (b)<-[:TYPE {cost: 17.0}]-(a)" +
    ", (c)<-[:TYPE {cost: 16.0}]-(a)" +
    ", (d)<-[:TYPE {cost: 19.0}]-(a)" +
    ", (e)<-[:TYPE {cost: 16.0}]-(a)" +
    ", (c)<-[:TYPE {cost: 3.0}]-(b)" +
    ", (d)<-[:TYPE {cost: 3.0}]-(b)" +
    ", (e)<-[:TYPE {cost: 11.0}]-(b)" +
    ", (b)<-[:TYPE {cost: 3.0}]-(c)" +
    ", (d)<-[:TYPE {cost: 4.0}]-(c)" +
    ", (e)<-[:TYPE {cost: 8.0}]-(c)" +
    ", (b)<-[:TYPE {cost: 3.0}]-(d)" +
    ", (c)<-[:TYPE {cost: 4.0}]-(d)" +
    ", (e)<-[:TYPE {cost: 12.0}]-(d)" +
    ", (b)<-[:TYPE {cost: 11.0}]-(e)" +        
    ", (c)<-[:TYPE {cost: 8.0}]-(e)" +
    ", (d)<-[:TYPE {cost: 12.0}]-(e)";

    @BeforeEach
    void setupGraph() throws Exception {
        registerProcedures(KArborescenceOutWriteProc.class, GraphProjectProc.class);
        var createQuery = GdsCypher.call(GRAPH_NAME)
            .graphProject()
            .withRelationshipProperty("cost")
            .loadEverything(Orientation.NATURAL)
            .yields();
        runQuery(createQuery);
    }  
    
    private long getSourceNode() {
        return idFunction.of("a");
    }

    @Test
    void testMinimum() {
        String query = GdsCypher.call(GRAPH_NAME)
                .algo("gds.arborescence.out.k")
                .writeMode()
                .addParameter("sourceNode", getSourceNode())
                .addParameter("relationshipWeightProperty", "cost")
                .addParameter("writeProperty", "cost")
                .addParameter("writeRelationshipType", "KMINA")
                .addParameter("objective", "minimum")
                .addParameter("k", 4)
                .yields(
                    "preProcessingMillis",
                    "computeMillis",
                    "writeMillis",
                    "effectiveNodeCount",
                    "relationshipsWritten"
                );
        runQueryWithRowConsumer(
            query,
            res -> {
                assertNotEquals(-1L, res.getNumber("writeMillis").longValue());
                assertEquals(4, res.getNumber("effectiveNodeCount").intValue());
            }
        );
        
        final long relCount = runQuery(
            "MATCH (a)-[:KMINA]->(b) RETURN id(a) as a, id(b) as b",
            //result -> result.stream().count()
            (result) -> {
            	long count = 0;
            	Iterator it = result.stream().iterator();
            	while (it.hasNext()) {
            		count++;
            		Object row = it.next();
            		System.out.println(row.toString());
            	}
            	return count;
            }                                    
        );

        assertEquals(relCount, 3);
        
    }

    @Test
    void testMaximum() {
        String query = GdsCypher.call(GRAPH_NAME)
                .algo("gds.arborescence.out.k")
                .writeMode()
                .addParameter("sourceNode", getSourceNode())
                .addParameter("relationshipWeightProperty", "cost")
                .addParameter("writeProperty", "cost")
                .addParameter("writeRelationshipType", "KMAXA")
                .addParameter("objective", "maximum")
                .addParameter("k", 4)
                .yields(
                    "preProcessingMillis",
                    "computeMillis",
                    "writeMillis",
                    "effectiveNodeCount",
                    "relationshipsWritten"
                );
        runQueryWithRowConsumer(
            query,
            res -> {
                assertNotEquals(-1L, res.getNumber("writeMillis").longValue());
                assertEquals(4, res.getNumber("effectiveNodeCount").intValue());
            }
        );
       
        long relCount = runQuery(
            "MATCH (a)-[:KMAXA]->(b) RETURN id(a) as a, id(b) as b",
            //result -> result.stream().count()
            (result) -> {
            	long count = 0;
            	Iterator it = result.stream().iterator();
            	while (it.hasNext()) {
            		count++;
            		Object row = it.next();
            		System.out.println(row.toString());
            	}
            	return count;
            }                                    
        );

        assertEquals(relCount, 3);
        
    }
    
}
