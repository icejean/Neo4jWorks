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

import org.neo4j.gds.paths.spanningtree.StatsResult;
import org.neo4j.gds.result.AbstractResultBuilder;

import java.util.Map;

public final class KArborescenceOutWriteResult extends StatsResult {


    public final long writeMillis;
    public final long relationshipsWritten;

    public KArborescenceOutWriteResult(
        long preProcessingMillis,
        long computeMillis,
        long writeMillis,
        long effectiveNodeCount,
        long relationshipsWritten,
        double totalCost,
        Map<String, Object> configuration
    ) {
        super(preProcessingMillis, computeMillis, effectiveNodeCount, totalCost, configuration);
        this.writeMillis = writeMillis;
        this.relationshipsWritten = relationshipsWritten;
    }

    public static class Builder extends AbstractResultBuilder<KArborescenceOutWriteResult> {

        long effectiveNodeCount;
        double totalWeight;

        Builder withEffectiveNodeCount(long effectiveNodeCount) {
            this.effectiveNodeCount = effectiveNodeCount;
            return this;
        }

        Builder withTotalWeight(double totalWeight) {
            this.totalWeight = totalWeight;
            return this;
        }

        @Override
        public KArborescenceOutWriteResult build() {
            return new KArborescenceOutWriteResult(
                preProcessingMillis,
                computeMillis,
                writeMillis,
                effectiveNodeCount,
                relationshipsWritten,
                totalWeight,
                java.util.Map.of()
            );
        }
    }
}
