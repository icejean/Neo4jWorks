package org.neo4j.gds.result;

/**
 * Local bridge — replaces GDS 2.5.x AbstractResultBuilder.
 * In GDS 2026.05.0 this class was removed.
 */
public abstract class AbstractResultBuilder<T> {

    public long preProcessingMillis = 0;
    public long computeMillis = 0;
    public long writeMillis = 0;
    public long relationshipsWritten = 0;
    public org.neo4j.gds.config.WriteConfig config = null;

    public AbstractResultBuilder<T> withPreProcessingMillis(long preProcessingMillis) {
        this.preProcessingMillis = preProcessingMillis;
        return this;
    }

    public AbstractResultBuilder<T> withComputeMillis(long computeMillis) {
        this.computeMillis = computeMillis;
        return this;
    }

    public AbstractResultBuilder<T> withWriteMillis(long writeMillis) {
        this.writeMillis = writeMillis;
        return this;
    }

    public AbstractResultBuilder<T> withRelationshipsWritten(long relationshipsWritten) {
        this.relationshipsWritten = relationshipsWritten;
        return this;
    }

    public AbstractResultBuilder<T> withConfig(org.neo4j.gds.config.WriteConfig config) {
        this.config = config;
        return this;
    }

    public abstract T build();
}
