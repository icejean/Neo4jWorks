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

import org.neo4j.gds.GraphAlgorithmFactory;
import org.neo4j.gds.api.Graph;
import org.neo4j.gds.collections.ha.HugeLongArray;
import org.neo4j.gds.mem.MemoryEstimation;
import org.neo4j.gds.mem.MemoryEstimations;
import org.neo4j.gds.core.utils.progress.tasks.ProgressTracker;
import org.neo4j.gds.core.utils.progress.tasks.Task;
import org.neo4j.gds.core.utils.progress.tasks.Tasks;
import org.neo4j.gds.core.utils.queue.HugeLongPriorityQueue;
import org.neo4j.gds.mem.MemoryUsage;
import org.neo4j.gds.arborescence.ArborescenceConfig;

public class ArborescenceInAlgorithmFactory<CONFIG extends ArborescenceConfig> extends GraphAlgorithmFactory<ZhuLiuIn, CONFIG> {

    @Override
    public ZhuLiuIn build(Graph graphOrGraphStore, CONFIG configuration, ProgressTracker progressTracker) {
        if (graphOrGraphStore.schema().isUndirected()) {
            throw new IllegalArgumentException(
                "The Arborescence algorithm works only with directed graphs. Please orient the edges properly");
        }
        return new ZhuLiuIn(
            graphOrGraphStore,
            org.neo4j.gds.spanningtree.SpanningTreeCompanion.parse(configuration.objective()),
            graphOrGraphStore.toMappedNodeId(configuration.sourceNode()),
            progressTracker
        );

    }

    @Override
    public String taskName() {
        return "ArborescenceIn";
    }

    @Override
    public MemoryEstimation memoryEstimation(CONFIG config) {
        return MemoryEstimations.builder(ZhuLiuIn.class)
            .perNode("Parent array", HugeLongArray::memoryEstimation)
            .add("Priority queue", HugeLongPriorityQueue.memoryEstimation())
            .perNode("visited", (n) -> (n / 64 + 1) * 8)
            .build();
    }
    public Task progressTask(Graph graph, CONFIG config) {
        return Tasks.task(
                taskName(),
                Tasks.leaf("ArborescenceIn", graph.nodeCount()),
                Tasks.leaf("Add relationship weights")                
            );

    }

}
