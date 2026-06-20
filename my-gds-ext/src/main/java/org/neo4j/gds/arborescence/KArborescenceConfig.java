package org.neo4j.gds.arborescence;

import org.neo4j.gds.annotation.Configuration;
import org.neo4j.gds.annotation.ValueClass;
import org.neo4j.gds.core.CypherMapWrapper;

/**
 * Config for K-constrained arborescence algorithms.
 * Adds k parameter on top of ArborescenceConfig.
 */
@ValueClass
@Configuration
@SuppressWarnings("immutables:subtype")
public interface KArborescenceConfig extends ArborescenceConfig {

    long k();

    static KArborescenceConfig of(CypherMapWrapper userInput) {
        return new KArborescenceConfigImpl(userInput);
    }
}
