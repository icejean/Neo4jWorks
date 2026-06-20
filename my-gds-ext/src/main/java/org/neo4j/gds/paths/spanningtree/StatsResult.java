package org.neo4j.gds.paths.spanningtree;

import org.neo4j.gds.result.AbstractResultBuilder;

/**
 * Local bridge — replicates GDS 2.5.x's paths.spanningtree.StatsResult.
 * Removed in GDS 2.7.0; replaced by GDS's own result classes or facade results.
 */
public class StatsResult {

    public final long preProcessingMillis;
    public final long computeMillis;
    public final long effectiveNodeCount;
    public final double totalCost;
    public final java.util.Map<String, Object> configuration;

    public StatsResult(
        long preProcessingMillis,
        long computeMillis,
        long effectiveNodeCount,
        double totalCost,
        java.util.Map<String, Object> configuration
    ) {
        this.preProcessingMillis = preProcessingMillis;
        this.computeMillis = computeMillis;
        this.effectiveNodeCount = effectiveNodeCount;
        this.totalCost = totalCost;
        this.configuration = configuration;
    }
}
