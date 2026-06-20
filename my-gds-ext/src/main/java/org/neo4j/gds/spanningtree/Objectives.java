package org.neo4j.gds.spanningtree;

import java.util.function.DoubleUnaryOperator;

/**
 * Local bridge — replaces GDS 2.5.x Prim.MIN_OPERATOR / MAX_OPERATOR.
 * In GDS 2026.05.0 these constants were removed.
 */
public final class Objectives {

    private Objectives() {}

    public static final DoubleUnaryOperator MIN_OPERATOR = a -> a;
    public static final DoubleUnaryOperator MAX_OPERATOR = a -> -a;
}
