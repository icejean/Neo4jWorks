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

import org.neo4j.gds.api.Graph;
import org.neo4j.gds.transaction.TransactionContext;
import org.neo4j.gds.core.utils.ProgressTimer;
import org.neo4j.gds.executor.AlgorithmSpec;
import org.neo4j.gds.executor.ComputationResultConsumer;
import org.neo4j.gds.executor.ExecutionContext;
import org.neo4j.gds.executor.GdsCallable;
import org.neo4j.gds.procedures.algorithms.configuration.NewConfigFunction;
import org.neo4j.gds.spanningtree.DirectedSpanningGraph;
import org.neo4j.gds.spanningtree.SpanningGraph;
import org.neo4j.gds.core.write.NativeRelationshipExporterBuilder;
import org.neo4j.gds.spanningtree.SpanningTree;
import org.neo4j.gds.arborescence.KArborescenceConfig;
import org.neo4j.gds.arborescence.KArborescenceInAlgorithmFactory;
import org.neo4j.gds.arborescence.ZhuLiuInK;

import java.util.stream.Stream;

import static org.neo4j.gds.executor.ExecutionMode.MUTATE_RELATIONSHIP;

@GdsCallable(name = "gds.arborescence.in.k.write",
             description = KArborescenceInWriteProc.DESCRIPTION,
             executionMode = MUTATE_RELATIONSHIP)
public class KArborescenceInWriteSpec implements AlgorithmSpec<ZhuLiuInK, SpanningTree, KArborescenceConfig, Stream<KArborescenceInWriteResult>, KArborescenceInAlgorithmFactory<KArborescenceConfig>> {

    private final TransactionContext txContext;

    public KArborescenceInWriteSpec(TransactionContext txContext) {
        this.txContext = txContext;
    }

    public KArborescenceInWriteSpec() {
        this.txContext = null;
    }


    @Override
    public String name() {
        return "KArborescenceIn";
    }

    @Override
    public KArborescenceInAlgorithmFactory<KArborescenceConfig> algorithmFactory(ExecutionContext executionContext) {
        return new KArborescenceInAlgorithmFactory<>();
    }

    @Override
    public NewConfigFunction<KArborescenceConfig> newConfigFunction() {
        return (__, config) -> KArborescenceConfig.of(config);

    }

    public ComputationResultConsumer<ZhuLiuInK, SpanningTree, KArborescenceConfig, Stream<KArborescenceInWriteResult>> computationResultConsumer() {

        return (computationResult, executionContext) -> {
            KArborescenceInWriteResult.Builder builder = new KArborescenceInWriteResult.Builder();

            if (computationResult.result().isEmpty()) {
                return Stream.of(builder.build());
            }

            Graph graph = computationResult.graph();
            ZhuLiuInK zhuliu = computationResult.algorithm();
            SpanningTree spanningTree = computationResult.result().get();            
            KArborescenceConfig config = computationResult.config();

            builder
                .withEffectiveNodeCount(spanningTree.effectiveNodeCount())
                .withTotalWeight(spanningTree.totalWeight());

            try (ProgressTimer ignored = ProgressTimer.start(builder::withWriteMillis)) {
                
                var spanningGraph = new org.neo4j.gds.spanningtree.DirectedSpanningGraph(graph, spanningTree);
                
                spanningGraph.forEachNode(nodeId -> {
                    if (spanningTree.parent(nodeId) >= 0) {
                        double cost = spanningTree.costToParent(nodeId);
                    }
                    return true;
                });

                spanningTree.forEach((s, t, w) -> {
                    return true;
                });

                new org.neo4j.gds.core.write.NativeRelationshipExporterBuilder(txContext)
                    .withGraph(spanningGraph)
                    .withIdMappingOperator(graph::toOriginalNodeId)
                    .withTerminationFlag(zhuliu.getTerminationFlag())
                    .withRelationPropertyTranslator(v -> org.neo4j.values.storable.Values.doubleValue(v))
                    .withProgressTracker(org.neo4j.gds.core.utils.progress.tasks.ProgressTracker.NULL_TRACKER)
                    .build()
                    .write(config.writeRelationshipType(), config.writeProperty());
            }builder.withComputeMillis(computationResult.computeMillis());
            builder.withPreProcessingMillis(computationResult.preProcessingMillis());
            builder.withRelationshipsWritten(spanningTree.effectiveNodeCount() - 1);
            builder.withConfig(config);
            return Stream.of(builder.build());
        };
    }
}
