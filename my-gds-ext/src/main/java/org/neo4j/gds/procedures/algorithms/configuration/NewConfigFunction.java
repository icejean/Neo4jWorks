package org.neo4j.gds.procedures.algorithms.configuration;

import org.neo4j.gds.config.AlgoBaseConfig;
import org.neo4j.gds.core.CypherMapWrapper;

/**
 * Local bridge — replicates GDS 2.7.0's missing NewConfigFunction type.
 * Used by AlgorithmSpec.newConfigFunction().
 * CONFIG bound must match GDS's AlgorithmSpec type parameter for correct erasure.
 */
@FunctionalInterface
public interface NewConfigFunction<CONFIG extends AlgoBaseConfig> {
    CONFIG apply(String username, CypherMapWrapper config);
}
