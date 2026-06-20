package org.neo4j.gds.arborescence;

import org.neo4j.gds.annotation.Configuration;
import org.neo4j.gds.annotation.ValueClass;
import org.neo4j.gds.config.AlgoBaseConfig;
import org.neo4j.gds.config.RelationshipWeightConfig;
import org.neo4j.gds.config.SourceNodeConfig;
import org.neo4j.gds.config.WritePropertyConfig;
import org.neo4j.gds.config.WriteRelationshipConfig;
import org.neo4j.gds.core.CypherMapWrapper;

import java.util.Collection;
import java.util.Optional;

/**
 * Config for arborescence algorithms.
 */
@ValueClass
@Configuration
@SuppressWarnings("immutables:subtype")
public interface ArborescenceConfig extends AlgoBaseConfig, SourceNodeConfig, RelationshipWeightConfig,
    WritePropertyConfig, WriteRelationshipConfig {

    /** objective as string: "minimum" or "maximum" */
    default String objective() {
        return "minimum";
    }

    /** validate that the graph is directed */
    @Configuration.GraphStoreValidationCheck
    default void validateDirectedGraph(
        org.neo4j.gds.api.GraphStore graphStore,
        Collection<org.neo4j.gds.NodeLabel> selectedLabels,
        Collection<org.neo4j.gds.RelationshipType> selectedRelationshipTypes
    ) {
        if (graphStore.schema().isUndirected()) {
            throw new IllegalArgumentException(
                "The arborescence algorithm works only with directed graphs.");
        }
    }

    static ArborescenceConfig of(CypherMapWrapper userInput) {
        return new ArborescenceConfigImpl(userInput);
    }
}
