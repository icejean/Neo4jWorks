package apoc.coll;

import org.neo4j.procedure.UserFunction;
import org.neo4j.procedure.Description;
import org.neo4j.procedure.Name;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class MyFunctions {
	
    @UserFunction
    @Description("apoc.coll.median([0.5,1,2.3])")
    public Double median(@Name("numbers") List<Number> values) {
    	if(values == null || values.isEmpty()) return null;
        Collections.sort(values, new Comparator<Number>() {
        	@Override
        	public int compare(Number o1, Number o2) {
        		Double d1 = (o1 == null) ? Double.POSITIVE_INFINITY : o1.doubleValue();
        		Double d2 = (o2 == null) ? Double.POSITIVE_INFINITY : o2.doubleValue();
        		return d1.compareTo(d2);
        	}
        });
        int size = values.size();
        if (size % 2 == 1) {
            return values.get(size /2).doubleValue();
        } else {
        	double first = values.get(size /2-1).doubleValue();
        	double second = values.get(size /2).doubleValue();
            return (first + second) / 2;
        }
	
    }
}
