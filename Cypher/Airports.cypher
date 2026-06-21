// https://github.com/neo4j-graph-examples
// https://github.com/neo4j-graph-examples/graph-data-science2
// https://github.com/neo4j-graph-examples/graph-data-science2/blob/main/documentation/gds_browser_guide2.adoc

// delete all nodes & relationships
match(n) detach delete n;

//CREATE CONSTRAINT airports IF NOT EXISTS ON (a:Airport) ASSERT a.iata IS UNIQUE;
//CREATE CONSTRAINT cities IF NOT EXISTS ON (c:City) ASSERT c.name IS UNIQUE;
//CREATE CONSTRAINT regions IF NOT EXISTS ON (r:Region) ASSERT r.name IS UNIQUE;
//CREATE CONSTRAINT countries IF NOT EXISTS ON (c:Country) ASSERT c.code IS UNIQUE;
//CREATE CONSTRAINT continents IF NOT EXISTS ON (c:Continent) ASSERT c.code IS UNIQUE;

CREATE CONSTRAINT airports IF NOT EXISTS FOR (a:Airport) REQUIRE a.iata IS UNIQUE;
CREATE CONSTRAINT cities IF NOT EXISTS FOR (c:City) REQUIRE c.name IS UNIQUE;
CREATE CONSTRAINT regions IF NOT EXISTS FOR (r:Region) REQUIRE r.name IS UNIQUE;
CREATE CONSTRAINT countries IF NOT EXISTS FOR (c:Country) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT continents IF NOT EXISTS FOR (c:Continent) REQUIRE c.code IS UNIQUE;


WITH
    //'https://raw.githubusercontent.com/neo4j-graph-examples/graph-data-science2/main/data/airport-node-list.csv'
    'file:///airport-node-list.csv'
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

WITH 
		//'https://raw.githubusercontent.com/neo4j-graph-examples/graph-data-science2/main/data/iroutes-edges.csv'
		'file:///iroutes-edges.csv'
		AS url
LOAD CSV WITH HEADERS FROM url AS row
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

    
match (n:City) return count(distinct n) as cities;

match (n:City)-[] return count(distinct n) as cities;   

match (n:City)-[:IN_COUNTRY]->(c:Country{code:"CN"}) return n.name;

match (n:City)-[:IN_COUNTRY]->(c:Country{code:"CN"}) return n.name; 

match (n:City)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
where n.name contains "Beijing"
return n.name;

match (n:City)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
where n.name contains "Zhuhai"
return n.name;

// CN-44
match (n:Region)<-[:IN_REGION]-(c:City{name:"Zhuhai"}) return n;
// Zhuhai Airport
match(n:Airport)-[:IN_CITY]->(c:City{name:"Zhuhai"}) return n.descr;

match(n:Airport{descr:"Zhuhai Airport"})-[r:IN_CITY]->(c:City) return n,r,c;

match(n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) return count(distinct n) as c;

match(n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) return n.descr as name;


call dbms.procedures() yield name,signature,description,mode
with name,signature,description,mode
where description contains "shortest"
return name,signature,description,mode
order by name


    
    
CALL {
    MATCH (start:Airport{descr:"Zhuhai Airport"})
    CALL gds.allShortestPaths.delta.stream('airportsNetwork_CN',
        { sourceNode:id(start),
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

MATCH (start:Airport{descr:"Zhuhai Airport"})-[r:HAS_ROUTE]->(target:Airport)
RETURN start, r, target

MATCH (startNode:Airport)-[r:HAS_ROUTE]->(targetNode:Airport)


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


MATCH (target:Airport)-[:IN_COUNTRY]->(c:Country{code:'CN'})
WITH target
MATCH path = (start:Airport{descr:"Zhuhai Airport"})-[r:HAS_ROUTE*1..3]->(target)
WITH *, relationships(path) as flights
UNWIND flights AS flight
WITH DISTINCT flight                   
MATCH (n:Airport)-[flight]->(m:Airport)
RETURN n.descr AS source, m.descr as target, flight.distance AS distance;  


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


# 清空图数据库
match(n) detach delete n;
CALL apoc.schema.assert({}, {})
show index
drop index index-name
call db.schema.visualization