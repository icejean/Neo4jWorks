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
package org.neo4j.gds.spanningtree;

import java.util.Comparator;

// Comparator of arcs
public class OrderArcs implements Comparator<Arc>{
	boolean isDesc = false;
	
	public OrderArcs(boolean isDesc) {
        this.isDesc = isDesc;
    } 
	
	public int compare(Arc arc1, Arc arc2) {
		if(isDesc) 
			return Double.compare(arc2.w,arc1.w);	// Ascending
		else
			return Double.compare(arc1.w,arc2.w);   // Descending
	}    	
	
	public boolean compare2(Arc arc1, Arc arc2) {
		if(isDesc) 
			return (arc2.w>arc1.w);	// Ascending
		else
			return (arc1.w>arc2.w);   // Descending
	}    	
}
