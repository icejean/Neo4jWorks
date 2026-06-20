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
package org.neo4j.gds.paths.kspanningtree;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.neo4j.gds.BaseProcTest5x;
import org.neo4j.gds.GdsCypher;
import org.neo4j.gds.Orientation;
import org.neo4j.gds.catalog.GraphProjectProc;
import org.neo4j.gds.extension.Neo4jGraph;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 *
 *         a                a
 *     1 /   \ 2          /  \
 *      /     \          /    \
 *     b --3-- c        b      c
 *     |       |   =>   |      |
 *     4       5        |      |
 *     |       |        |      |
 *     d --6-- e        d      e
 */
class MyKSpanningTreeWriteProcTest extends BaseProcTest5x {

    @Neo4jGraph
    static final String DB_CYPHER = "CREATE(a:Node) " +
                                    "CREATE(b:Node) " +
                                    "CREATE(c:Node) " +
                                    "CREATE(d:Node) " +
                                    "CREATE(e:Node) " +
                                   // "CREATE(z:Node) " +
                                    "CREATE (a)-[:TYPE {cost:1.0}]->(b) " +
                                    "CREATE (a)-[:TYPE {cost:2.0}]->(c) " +
                                    "CREATE (b)-[:TYPE {cost:3.0}]->(c) " +
                                    "CREATE (b)-[:TYPE {cost:4.0}]->(d) " +
                                    "CREATE (c)-[:TYPE {cost:5.0}]->(e) " +
                                    "CREATE (d)-[:TYPE {cost:6.0}]->(e)";

    @BeforeEach
    void setup() throws Exception {
        registerProcedures(MyKSpanningTreeWriteProc.class, GraphProjectProc.class);
        var createQuery = GdsCypher.call(DEFAULT_GRAPH_NAME)
            .graphProject()
            .withAnyLabel()
            .withRelationshipType("TYPE", Orientation.UNDIRECTED)
            .withRelationshipProperty("cost")
            .yields();
        runQuery(createQuery);
    }


    private long getSourceNode() {
        return idFunction.of("a");
    }

    @ParameterizedTest
    @ValueSource(strings = {"minimum", "maximum"})
    void testYields(String objective) {
        String query = GdsCypher.call(DEFAULT_GRAPH_NAME)
            .algo("gds.MyKSpanningTree")
            .writeMode()
            .addParameter("sourceNode", getSourceNode())
            .addParameter("relationshipWeightProperty", "cost")
            .addParameter("writeProperty", "cost")
            .addParameter("writeRelationshipType", "KMST")
            .addParameter("objective", objective)
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
                assertThat(res.getNumber("preProcessingMillis").longValue()).isGreaterThanOrEqualTo(0L);
                assertThat(res.getNumber("computeMillis").longValue()).isGreaterThanOrEqualTo(0L);
                assertThat(res.getNumber("writeMillis").longValue()).isGreaterThanOrEqualTo(0L);
                assertThat(res.getNumber("effectiveNodeCount").longValue()).isEqualTo(4L);
                assertThat(res.getNumber("relationshipsWritten").longValue()).isEqualTo(3L);

            }
        );

        final long relCount = runQuery(
            "MATCH (a)-[:KMST]->(b) RETURN id(a) AS a, id(b) AS b",
            result -> result.stream().count()
        );

        assertEquals(relCount, 3);
    }

}
