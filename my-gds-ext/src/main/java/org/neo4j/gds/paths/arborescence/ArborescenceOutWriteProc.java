/*
 * Copyright (c) "Jean Ye"
 * ZhuHai Taxation Bureau, China [1793893070@qq.com]
 *
 * This file is an addition to Neo4j.
 */
package org.neo4j.gds.paths.arborescence;

import org.neo4j.gds.BaseProc;
import org.neo4j.gds.executor.MemoryEstimationExecutor;
import org.neo4j.gds.executor.ProcedureExecutor;
import org.neo4j.gds.applications.algorithms.machinery.MemoryEstimateResult;
import org.neo4j.procedure.Description;
import org.neo4j.procedure.Name;
import org.neo4j.procedure.Procedure;

import java.util.Map;
import java.util.stream.Stream;

import static org.neo4j.procedure.Mode.READ;
import static org.neo4j.procedure.Mode.WRITE;

public class ArborescenceOutWriteProc extends BaseProc {

    static final String procedure = "gds.arborescence.out.write";

    static final String DESCRIPTION = "Custom algorithm";

    @Procedure(value = procedure, mode = WRITE)
    @Description(DESCRIPTION)
    public Stream<ArborescenceOutWriteResult> compute(
        @Name(value = "graphName") String graphName,
        @Name(value = "configuration", defaultValue = "{}") Map<String, Object> configuration
    ) {
        return new ProcedureExecutor<>(
            new ArborescenceOutWriteSpec(transactionContext()),
            executionContext()
        ).compute(graphName, configuration);
    }

    @Procedure(value = procedure + ".estimate", mode = READ)
    @Description(DESCRIPTION)
    public Stream<MemoryEstimateResult> estimate(
        @Name(value = "graphNameOrConfiguration") Object graphName,
        @Name(value = "algoConfiguration") Map<String, Object> configuration
    ) {
        return new MemoryEstimationExecutor<>(
            new ArborescenceOutWriteSpec(transactionContext()),
            executionContext(),
            transactionContext()
        ).computeEstimate(graphName, configuration);
    }
}
