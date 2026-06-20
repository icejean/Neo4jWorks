// Neo4j GDS 库的实现-----------------------------------------------------------------------------
SHOW PROCEDURES yield name,signature,description,mode
where name contains "alpha"
return name,signature,description,mode
order by name;

SHOW FUNCTIONS yield name,signature,description,aggregating
where name contains "alpha"
return name,signature,description,aggregating
order by name;


// Minimum Weight Spanning Tree Production
// https://neo4j.com/docs/graph-data-science/current/algorithms/minimum-weight-spanning-tree/

match(n) detach delete n;

CREATE (a:Place {id: 'A'}),
       (b:Place {id: 'B'}),
       (c:Place {id: 'C'}),
       (d:Place {id: 'D'}),
       (e:Place {id: 'E'}),
       (f:Place {id: 'F'}),
       (g:Place {id: 'G'}),
       (d)-[:LINK {cost:4}]->(b),
       (d)-[:LINK {cost:6}]->(e),
       (b)-[:LINK {cost:1}]->(a),
       (b)-[:LINK {cost:3}]->(c),
       (a)-[:LINK {cost:2}]->(c),
       (c)-[:LINK {cost:5}]->(e),
       (f)-[:LINK {cost:1}]->(g);
       
match (n)-[r]-(m) return n,r,m;


CALL gds.graph.drop("graph") YIELD graphName;
       
CALL gds.graph.project(
  'graph',
  'Place',
  {
    LINK: {
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  }
)


// 最小生成树 --------------------------------------------------------------------------------
MATCH (n:Place {id: 'D'})
CALL gds.spanningTree.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MINST'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH path = (n:Place {id: 'D'})-[:MINST*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel).id AS Source, endNode(rel).id AS Destination, rel.writeCost AS Cost


// 最大生成树 -------------------------------------------------------------------------------
MATCH (n:Place {id: 'D'})
CALL gds.spanningTree.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MAXST',
  objective: 'maximum'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH path = (n:Place {id: 'D'})-[:MAXST*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel).id AS Source, endNode(rel).id AS Destination, rel.writeCost AS Cost

// Minimum Weight k-Spanning Tree alpha
// https://neo4j.com/docs/graph-data-science/current/algorithms/k-minimum-weight-spanning-tree/


// K最小生成树的结果是对的 --------------------------------------------------------------------
MATCH (n:Place{id: 'A'})
CALL gds.kSpanningTree.write('graph', {
  k: 3,
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty:'kmin'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis,computeMillis,writeMillis, effectiveNodeCount;


// Result is incorrert
MATCH (n)
WITH n.kmin AS p, count(n) AS c
WHERE c = 3
MATCH (n)
WHERE n.kmin = p
RETURN n.id As Place, p as Partition       


// K最大生成树的结果是对的 -------------------------------------------------------------------
MATCH (n:Place{id: 'D'})
CALL gds.kSpanningTree.write('graph', {
  k: 3,
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty:'kmax',
  objective: 'maximum'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis,computeMillis,writeMillis, effectiveNodeCount;


MATCH (n)
WITH n.kmax AS p, count(n) AS c
WHERE c = 3
MATCH (n)
WHERE n.kmax = p
RETURN n.id As Place, p as Partition


// Minimum Directed Steiner Tree beta
// https://neo4j.com/docs/graph-data-science/current/algorithms/directed-steiner-tree/
// 至今没有有效的算法找到最优解

match(n) detach delete n;

CREATE (a:Place {id: 'A'}),
       (b:Place {id: 'B'}),
       (c:Place {id: 'C'}),
       (d:Place {id: 'D'}),
       (e:Place {id: 'E'}),
       (f:Place {id: 'F'}),
       (a)-[:LINK {cost:10}]->(f),
       (a)-[:LINK {cost:1}]->(b),
       (a)-[:LINK {cost:7}]->(e),
       (b)-[:LINK {cost:1}]->(c),
       (c)-[:LINK {cost:4}]->(d),
       (c)-[:LINK {cost:6}]->(e),
       (f)-[:LINK {cost:3}]->(d);
       

match (n)-[r]-(m) return n,r,m;
       
CALL gds.graph.project(
  'graph',
  'Place',
  {
    LINK: {
      properties: 'cost'
    }
  }
)       


MATCH (a:Place{id: 'A'}), (d:Place{id: 'D'}),(e:Place{id: 'E'}),(f:Place{id: 'F'})
CALL gds.steinerTree.write('graph', {
  sourceNode: a,
  targetNodes: [d, e, f],
  relationshipWeightProperty: 'cost',
  writeProperty: 'steinerWeight',
  writeRelationshipType: 'STEINER'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;

MATCH path = (a:Place {id: 'A'})-[:STEINER*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel).id AS Source, endNode(rel).id AS Destination, rel.steinerWeight AS weight
ORDER BY Source, Destination

match (n)-[r]-(m) return n,r,m;

// Simple rerouting改进 ------------------------------------------------------------------------

MATCH (a:Place{id: 'A'}), (d:Place{id: 'D'}),(e:Place{id: 'E'}),(f:Place{id: 'F'})
CALL gds.steinerTree.write('graph', {
  sourceNode: a,
  targetNodes: [d, e, f],
  relationshipWeightProperty: 'cost',
  writeProperty: 'steinerWeight',
  applyRerouting: true,
  writeRelationshipType: 'STEINER2'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH path = (a:Place {id: 'A'})-[:STEINER2*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel).id AS Source, endNode(rel).id AS Destination, rel.steinerWeight AS weight
ORDER BY Source, Destination


// Extended rerouting 改进 -----------------------------------------------------------------------

CALL gds.graph.project(
  'inverseGraph',
  'Place',
  {
    LINK: {
      properties: 'cost', indexInverse: true
    }
  }
)


MATCH (a:Place{id: 'A'}), (d:Place{id: 'D'}),(e:Place{id: 'E'}),(f:Place{id: 'F'})
CALL gds.steinerTree.write('inverseGraph', {
  sourceNode: a,
  targetNodes: [d, e, f],
  relationshipWeightProperty: 'cost',
  writeProperty: 'steinerWeight',
  applyRerouting: true,
  writeRelationshipType: 'STEINER3'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH path = (a:Place {id: 'A'})-[:STEINER3*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel).id AS Source, endNode(rel).id AS Destination, rel.steinerWeight AS weight
ORDER BY Source, Destination




// My K spanning tree algorithm test --------------------------------------

// Ensure the algorithm procedure is loaded
SHOW PROCEDURES yield name,signature,description,mode
where name contains "MyKSpanningTree"
return name,signature,description,mode
order by name;

// Create a graph for test ------------------------------------------------
match(n) detach delete n;

CREATE (a:Place {id: 'A'}),
       (b:Place {id: 'B'}),
       (c:Place {id: 'C'}),
       (d:Place {id: 'D'}),
       (e:Place {id: 'E'}),
       (d)-[:LINK {cost:4}]->(b),
       (d)-[:LINK {cost:6}]->(e),
       (b)-[:LINK {cost:1}]->(a),
       (b)-[:LINK {cost:3}]->(c),
       (a)-[:LINK {cost:2}]->(c),
       (c)-[:LINK {cost:5}]->(e);
       
match (n)-[r]-(m) return n,r,m;

// Create a graph projection for running the algorithm procedure
CALL gds.graph.drop("graph") YIELD graphName;
       
CALL gds.graph.project(
  'graph',
  'Place',
  {
    LINK: {
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  }
)

// Minimum sapnning tree ----------------------------------------------------
MATCH (n:Place {id: 'A'})
CALL gds.spanningTree.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MINST'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;
 

// My K minium sapnning tree
MATCH (n:Place {id: 'A'})
CALL gds.MyKSpanningTree.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'KMINST',
  k:4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;



// Maximum spanning tree-----------------------------------------------------
MATCH (n:Place {id: 'A'})
CALL gds.spanningTree.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MAXST',
  objective: 'maximum'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;

// My K maximum sapnning tree
MATCH (n:Place {id: 'A'})
CALL gds.MyKSpanningTree.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'KMAXST',
  objective: 'maximum',
  k:4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


// Show and check the algorithm result
match (n)-[r]-(m) return n,r,m;


// 注意：GDS 2.7.0以后 totalWeight改成totalCost
//---最小树形图测试   入度方向 供应链------------------------------------------------------------------------------------
         
match(n) detach delete n;
  
//创建测试图       
CREATE(a:Node {name: 'a'}), 
			(b:Node {name: 'b'}),
			(c:Node {name: 'c'}), 
			(d:Node {name: 'd'}),
			(e:Node {name: 'e'}), 
			(b)-[:TYPE {cost:17}]->(a),	(c)-[:TYPE {cost:16}]->(a),	(d)-[:TYPE {cost:19}]->(a),	(e)-[:TYPE {cost:16}]->(a), 
			(c)-[:TYPE {cost:3}]->(b),	(d)-[:TYPE {cost:3}]->(b), (e)-[:TYPE {cost:11}]->(b), 
			(b)-[:TYPE {cost:3}]->(c), (d)-[:TYPE {cost:4}]->(c), (e)-[:TYPE {cost:8}]->(c),
			(b)-[:TYPE {cost:3}]->(d),(c)-[:TYPE {cost:4}]->(d), (e)-[:TYPE {cost:12}]->(d),
			(b)-[:TYPE {cost:11}]->(e),	(c)-[:TYPE {cost:8}]->(e), (d)-[:TYPE {cost:12}]->(e);

CALL gds.graph.drop("graph") YIELD graphName;

//创建算法测试用的投影 
CALL gds.graph.project(
  'graph',
  'Node',
  {
    LINK: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'
    }
  }
)     


// 估计内存开销
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.in.write.estimate('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MINSA'
})
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory
RETURN nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

//最小树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.in.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MINSA'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;

//K最小树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.in.k.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'KMINSA',
  k:4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;

//最大树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.in.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  objective: 'maximum',
  writeRelationshipType: 'MAXSA'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;

//K最大树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.in.k.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  objective: 'maximum',
  writeRelationshipType: 'KMAXSA',
  k:4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;


// Show and check the algorithm result
match (n)-[r]-(m) return n,r,m;


//---最小树形图测试  出度方向  销售链------------------------------------------------------------------------------------

CALL gds.graph.drop( 'graph');

match(n) detach delete n;

CREATE(a:Node {name: 'a'}), 
			(b:Node {name: 'b'}),
			(c:Node {name: 'c'}), 
			(d:Node {name: 'd'}),
			(e:Node {name: 'e'}), 
			(b)<-[:TYPE {cost:17}]-(a),	(c)<-[:TYPE {cost:16}]-(a),	(d)<-[:TYPE {cost:19}]-(a),	(e)<-[:TYPE {cost:16}]-(a), 
			(c)<-[:TYPE {cost:3}]-(b),	(d)<-[:TYPE {cost:3}]-(b), (e)<-[:TYPE {cost:11}]-(b), 
			(b)<-[:TYPE {cost:3}]-(c), (d)<-[:TYPE {cost:4}]-(c), (e)<-[:TYPE {cost:8}]-(c),
			(b)<-[:TYPE {cost:3}]-(d), (c)<-[:TYPE {cost:4}]-(d), (e)<-[:TYPE {cost:12}]-(d),
			(b)<-[:TYPE {cost:11}]-(e),	(c)<-[:TYPE {cost:8}]-(e), (d)<-[:TYPE {cost:12}]-(e);

CALL gds.graph.project(
  'graph',
  'Node',
  {
    LINK: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'
    }
  }
) 

//最小树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.out.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'MINSA'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;

//K最小树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.out.k.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  writeRelationshipType: 'KMINSA',
  k:4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;

//最大树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.out.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  objective: 'maximum',
  writeRelationshipType: 'MAXSA'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;

//K最大树形图
MATCH (n:Node {name: 'a'})
CALL gds.arborescence.out.k.write('graph', {
  sourceNode: n,
  relationshipWeightProperty: 'cost',
  writeProperty: 'writeCost',
  objective: 'maximum',
  writeRelationshipType: 'KMAXSA',
  k:4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount, totalCost;


// Show and check the algorithm result
match (n)-[r]-(m) return n,r,m;


SHOW PROCEDURES yield name,signature,description,mode
where name contains "arborescence" or  name contains "My"
return name,signature,description,mode
order by name;


//加载机场航线网络 --------------------------------------------------------------------------------------------
// https://github.com/neo4j-graph-examples
// https://github.com/neo4j-graph-examples/graph-data-science2
// https://github.com/neo4j-graph-examples/graph-data-science2/blob/main/documentation/gds_browser_guide2.adoc

// delete all nodes & relationships
match(n) detach delete n;

CREATE CONSTRAINT airports IF NOT EXISTS FOR (a:Airport) REQUIRE a.iata IS UNIQUE;
CREATE CONSTRAINT cities IF NOT EXISTS FOR (c:City) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT regions IF NOT EXISTS FOR (r:Region) REQUIRE r.name IS UNIQUE;
CREATE CONSTRAINT countries IF NOT EXISTS FOR (c:Country) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT continents IF NOT EXISTS FOR (c:Continent) REQUIRE c.code IS UNIQUE;


WITH
    'https://raw.githubusercontent.com/neo4j-graph-examples/graph-data-science2/main/data/airport-node-list.csv'
    AS url
LOAD CSV WITH HEADERS FROM url AS row
MERGE (a:Airport {iata: row.iata})
MERGE (ci:City {name: row.city})
MERGE (r:Region {name: row.region})
MERGE (co:Country {code: row.country})
MERGE (con:Continent {name: row.continent})
MERGE (a)-[:IN_CITY]->(ci)
MERGE (a)-[:IN_COUNTRY]->(co)
MERGE (ci)-[:IN_COUNTRY]->(co)
MERGE (r)-[:IN_COUNTRY]->(co)
MERGE (a)-[:IN_REGION]->(r)
MERGE (ci)-[:IN_REGION]->(r)
MERGE (a)-[:ON_CONTINENT]->(con)
MERGE (ci)-[:ON_CONTINENT]->(con)
MERGE (co)-[:ON_CONTINENT]->(con)
MERGE (r)-[:ON_CONTINENT]->(con)
SET a.id = row.id,
    a.icao = row.icao,
    a.city = row.city,
    a.descr = row.descr,
    a.runways = toInteger(row.runways),
    a.longest = toInteger(row.longest),
    a.altitude = toInteger(row.altitude),
    a.location = point({latitude: toFloat(row.lat), longitude: toFloat(row.lon)});
    
create index for (n:Airport) on (n.location);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/neo4j-graph-examples/graph-data-science2/main/data/iroutes-edges.csv' AS row
MATCH (source:Airport {iata: row.src})
MATCH (target:Airport {iata: row.dest})
MERGE (source)-[r:HAS_ROUTE]->(target)
ON CREATE SET r.distance = toInteger(row.dist);

CALL gds.graph.exists('airportsNetwork_CN')
  YIELD graphName, exists
WHERE NOT exists
CALL gds.graph.project.cypher(
    'airportsNetwork_CN',
    'MATCH (n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
                RETURN id(n) AS id',
    'MATCH (startNode:Airport)-[r:HAS_ROUTE]->(targetNode:Airport),
                        (startNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}),
                        (targetNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})
                RETURN id(startNode) AS source, id(targetNode) AS target, r.distance AS distance'
) YIELD
  graphName AS graph, nodeQuery, nodeCount AS nodes, relationshipQuery, relationshipCount AS rels     
RETURN graphName, nodes, rels;   

CALL gds.graph.drop( 'airportsNetwork_CN');  

// apoc.coll.median()是我写的用户自定义函数，求数组的中位数，参数是一个数组：apoc.coll.median([0.5,1,2.3])
// 与apoc.agg.median()的功能不一样，它的参数是一个变量名：apoc.agg.median(value :: ANY) :: ANY
MATCH (china:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})
WITH COLLECT(china.id) AS targets
MATCH path = (source:Airport{descr:"Zhuhai Airport"})-[r:HAS_ROUTE*2..3]->(target)
WHERE target.descr = source.descr
      AND ALL( node IN nodes(path) where node.id IN targets)
WITH path, [r in relationships(path)|r.distance] AS distances, 0.5 AS amplitude, 500 AS threshold
WITH path, apoc.coll.avg(distances) AS avgDist, apoc.coll.min(distances) as minDist, apoc.coll.max(distances) as maxDist
WHERE minDist/avgDist >= (1-amplitude) AND maxDist/avgDist <= (1+amplitude) AND avgDist >= threshold
//WITH path, apoc.coll.median(distances) AS medianDist, apoc.coll.min(distances) as minDist, apoc.coll.max(distances) as maxDist
//WHERE minDist/medianDist >= (1-amplitude) AND maxDist/medianDist <= (1+amplitude) AND medianDist >= threshold
WITH path, relationships(path) as flights
UNWIND flights AS flight
WITH DISTINCT flight
MATCH (n:Airport)-[flight]->(m:Airport)
RETURN n.descr AS source, m.descr as target, flight.distance AS distance; 

SHOW FUNCTIONS yield name,signature,description,aggregating
where name contains "apoc.coll"
return name,signature,description,aggregating
order by name;

RETURN apoc.coll.median([0.5,1,2.3]) AS result;


// gds.allShortestPaths.delta.stream的调用稍有变化，需要改一下。
CALL {
    MATCH (start:Airport{descr:"Zhuhai Airport"})
    CALL gds.allShortestPaths.delta.stream('airportsNetwork_CN',
        { sourceNode:start,
          relationshipWeightProperty:'distance',
          delta: 3.0 })
    YIELD targetNode AS nodeId, totalCost AS distance, path
    RETURN  nodeId, distance, path
    ORDER BY distance
    //跳过第一条，是自己
    SKIP 1
    //LIMIT 10;
    }
WITH path
WHERE length(path)<=3 
WITH nodes(path) AS pnodes                                         
UNWIND range(0, size(pnodes)-1) AS index
WITH pnodes[index] AS current, pnodes[index+1] AS next
MATCH (current)-[r:HAS_ROUTE]->(next)
RETURN current.descr AS source, next.descr as target, r.distance AS distance;        