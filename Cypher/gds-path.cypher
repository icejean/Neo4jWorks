//GDS 1.4.0
//载入实例数据，部分欧洲公路网
LOAD CSV WITH HEADERS FROM "file:///E:/Neo4j/0636920233145-master/data/transport-nodes.csv"  AS row
MERGE (place:Place {id:row.id})
SET place.latitude = toFloat(row.latitude),
    place.longitude = toFloat(row.latitude),
    place.population = toInteger(row.population)

LOAD CSV WITH HEADERS FROM "file:///E:/Neo4j/0636920233145-master/data/transport-relationships.csv" AS row
MATCH (origin:Place {id: row.src})
MATCH (destination:Place {id: row.dst})
MERGE (origin)-[:EROAD {distance: toInteger(row.cost)}]->(destination)
    
//广度优先遍历，带目标节点
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.bfs.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL'  //NATURAL, REVERSE, UNDIRECTED
     }},
     startNode:id(source),
     targetNodes:[id(destination)]})
YIELD path
UNWIND [n IN NODES(path) | n.id] AS place
return place

//广度优先遍历，所有节点
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.bfs.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL'  //NATURAL, REVERSE, UNDIRECTED
     }},
     startNode:id(source)
})
YIELD path
UNWIND [n IN NODES(path) | n.id] AS place
return place

//深度优先遍历，带目标节点
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.dfs.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL'  //NATURAL, REVERSE, UNDIRECTED
     }},
     startNode:id(source),
     targetNodes:[id(destination)]})
YIELD path
UNWIND [n IN NODES(path) | n.id] AS place
return place

//深度优先遍历，所有节点
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.dfs.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL'  //NATURAL, REVERSE, UNDIRECTED
     }},
     startNode:id(source)
})
YIELD path
UNWIND [n IN NODES(path) | n.id] AS place
return place



// 最短路径 Dijkstra 算法，非加权
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.shortestPath.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     relationshipWeightProperty:null
})
YIELD nodeId, cost
RETURN gds.util.asNode(nodeId).id AS place, cost

//计算非加权最短路径的总距离
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.shortestPath.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     relationshipWeightProperty:null
})
YIELD nodeId, cost

WITH collect(gds.util.asNode(nodeId)) AS path   //组成完整路径
UNWIND range(0, size(path)-1) AS index          //获取每一跳的距离
WITH path[index] AS current, path[index+1] AS next
WITH current, next, [(current)-[r:EROAD]-(next) | r.distance][0] AS distance  //模式推导式
//计算当前一步的累加距离
WITH collect({current: current, next:next, distance: distance}) AS stops 
UNWIND range(0, size(stops)-1) AS index
WITH stops[index] AS location, stops, index
RETURN location.current.id AS place,
       reduce(acc=0.0,
              distance in [stop in stops[0..index] | stop.distance] |
              acc + distance) AS cost
              
// 最短路径 Dijkstra 算法，加权
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.shortestPath.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     relationshipWeightProperty:'distance'
})
YIELD nodeId, cost
RETURN gds.util.asNode(nodeId).id AS place, cost

// 最短路径 A*算法，加权，  f(n) = g(n) + h(n)， 需要经纬度数据参考以估计 g(n) 与 h(n)
MATCH (source:Place {id: "Amsterdam"}), (destination:Place {id: "London"})
CALL gds.alpha.shortestPath.astar.stream({
     nodeProjection:{
     Place:{
         properties: ['longitude','latitude']
     }},
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     propertyKeyLat:'latitude',
     propertyKeyLon:'longitude',
     relationshipWeightProperty:'distance'
})
YIELD nodeId, cost
RETURN gds.util.asNode(nodeId).id AS place, cost     


// Yen K最短路径算法
MATCH (source:Place {id: "Gouda"}), (destination:Place {id: "Felixstowe"})
CALL gds.alpha.kShortestPaths.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     k: 5,
     relationshipWeightProperty:'distance'
})
YIELD index, nodeIds, costs
RETURN [node in gds.util.asNodes(nodeIds) | node.id] AS place, costs,
       reduce(acc = 0.0, cost IN costs | acc+cost) AS totalCost         
 
// Yen K最短路径算法，返回图 
MATCH (source:Place {id: "Gouda"}), (destination:Place {id: "Felixstowe"})
CALL gds.alpha.kShortestPaths.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     k: 5,
     relationshipWeightProperty:'distance',
     path: true
})
YIELD path
RETURN path         

//回写Yen K最短路径算法，查询显示
MATCH (source:Place {id: "Gouda"}), (destination:Place {id: "Felixstowe"})
CALL gds.alpha.kShortestPaths.write({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'UNDIRECTED'
     }},
     startNode:source,
     endNode:destination,
     k: 3,
     relationshipWeightProperty:'distance'
})
YIELD resultCount
RETURN resultCount

match p=()-[r:PATH_0|PATH_1|PATH_2]->() return p limit 5

//单源最短路径
MATCH (source:Place {id: "Amsterdam"})
CALL gds.alpha.shortestPath.deltaStepping.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL' //NATURAL, REVERSE, UNDIRECTED
     }},
     startNode:source,
     relationshipWeightProperty:'distance',
     delta: 3.0
})
YIELD nodeId, distance
RETURN gds.util.asNode(nodeId).id AS place, distance AS cost
ORDER BY cost

//所有点之间的最短路径
CALL gds.alpha.allShortestPaths.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL' //NATURAL, REVERSE, UNDIRECTED
     }},
     relationshipWeightProperty:'distance'
})
YIELD sourceNodeId, targetNodeId, distance
WITH sourceNodeId, targetNodeId, distance
WHERE gds.util.isFinite(distance) = true

MATCH (source:Place) WHERE id(source)= sourceNodeId
MATCH (target:Place) WHERE id(target)= targetNodeId
WITH source, target, distance WHERE source<>target

RETURN source.id as source, target.id as target, distance
ORDER BY distance, source, target


//随机漫步
MATCH (source:Place {id: "Amsterdam"})
CALL gds.alpha.randomWalk.stream({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL' //NATURAL, REVERSE, UNDIRECTED
     }},
     start:id(source),
     steps:5,
     walks:2
})
YIELD nodeIds
UNWIND nodeIds AS nodeId
RETURN gds.util.asNode(nodeId).id AS place

//最小生成树
MATCH (source:Place {id: "Amsterdam"})
CALL gds.alpha.spanningTree.minimum.write({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL' //NATURAL, REVERSE, UNDIRECTED
     }},
     startNodeId:id(source),
     relationshipWeightProperty:'distance',
     writeProperty: 'MINST',
     weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis, computeMillis, writeMillis, effectiveNodeCount

MATCH path=(source:Place {id: "Amsterdam"})-[:MINST*]->()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
//RETURN startNode(rel).id AS source, endNode(rel) AS destination, rel.writeCost AS cost  //不显示图
RETURN startNode(rel), endNode(rel) , rel   //显示图

//K最小生成树，结果不对
MATCH (source:Place {id: "Amsterdam"})
CALL gds.alpha.spanningTree.kmin.write({
     nodeProjection:'Place',
     relationshipProjection:{
     EROAD:{
         type:'EROAD',
         properties:'distance',
         orientation:'NATURAL'
     }},
     startNodeId:id(source),
     relationshipWeightProperty:'distance',
     writeProperty: 'kminst',
     k: 3
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis, computeMillis, writeMillis, effectiveNodeCount

//没有输出，结果不对
MATCH (n:Place)
WITH n.id AS place, n.kminst AS partition, count(*) AS count
WHERE count = 3
RETURN place, partition

//查看全图，kminst=3的有2个节点，其余为0或9，但源节点与kminst=3节点组成的路径，总距离并非最小。
Match (n)-[r]->(m)
return n,r,m

//返回K最小生成树，但总距离并非最小
match (n)-[r]->(m)
where (n.id="Amsterdam" or n.kminst=3)and m.kminst = 3 
return n,r,m


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

MATCH (n:Place{id: 'D'})
CALL gds.alpha.spanningTree.kmin.write({
  nodeProjection: 'Place',
  relationshipProjection: {
    LINK: {
      type: 'LINK',
      properties: 'cost'
    }
  },
  k: 3,
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty:'kminst'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis,writeMillis, effectiveNodeCount;
       
MATCH (n:Place)
WITH n.kminst AS Partition, count(*) AS count
WHERE count = 3
MATCH (n:Place)
WHERE n.kminst=Partition
RETURN n

MATCH (n:Place{id: 'D'})
CALL gds.alpha.spanningTree.kmax.write({
  nodeProjection: 'Place',
  relationshipProjection: {
    LINK: {
      type: 'LINK',
      properties: 'cost'
    }
  },
  k: 3,
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty:'kmaxst'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis,writeMillis, effectiveNodeCount;

MATCH (n:Place)
WITH n.kmaxst AS Partition, count(*) AS count
WHERE count = 3
MATCH (n:Place)
WHERE n.kmaxst=Partition
RETURN n

///—————K最小生产树测试————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

match(n) detach delete n;

CREATE (a:Place {name: 'A'}),
       (b:Place {name: 'B'}),
       (c:Place {name: 'C'}),
       (d:Place {name: 'D'}),
       (e:Place {name: 'E'}),
       (d)-[:LINK {cost:4}]->(b),
       (d)-[:LINK {cost:6}]->(e),
       (b)-[:LINK {cost:1}]->(a),
       (b)-[:LINK {cost:3}]->(c),
       (a)-[:LINK {cost:2}]->(c),
       (c)-[:LINK {cost:5}]->(e);

MATCH (n:Place {name: 'A'})
CALL gds.alpha.spanningTree.mykmin.write({
  nodeProjection: 'Place',
  relationshipProjection: {
    LINK: {
      type: 'LINK',
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMINST',
  weightWriteProperty: 'writeCost',
  k:4
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis, computeMillis, writeMillis, effectiveNodeCount;

MATCH path = (n:Place {name: 'A'})-[:KMINST*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel

MATCH (n:Place {name: 'A'})
CALL gds.alpha.spanningTree.mykmax.write({
  nodeProjection: 'Place',
  relationshipProjection: {
    LINK: {
      type: 'LINK',
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMAX',
  weightWriteProperty: 'writeCost',
  k:4
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis, computeMillis, writeMillis, effectiveNodeCount;

MATCH path = (n:Place {name: 'A'})-[:KMAX*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel
       
MATCH (n:Place {name: 'A'})
CALL gds.alpha.spanningTree.minimum.write({
  nodeProjection: 'Place',
  relationshipProjection: {
    LINK: {
      type: 'LINK',
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MINST',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis, computeMillis, writeMillis, effectiveNodeCount;

MATCH path = (n:Place {name: 'A'})-[:MINST*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel

MATCH (n:Place{name: 'A'})
CALL gds.alpha.spanningTree.maximum.write({
  nodeProjection: 'Place',
  relationshipProjection: {
    LINK: {
      type: 'LINK',
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MAXST',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Place {name: 'A'})-[:MAXST*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel

MATCH (n:Place)-[r:MAXST]-(m)
return n,r,m

//---最小树形图测试   入度方向 供应链--------------------------------------------------------------------------------------------------------------------------------
match(n) detach delete n;

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

MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescence.minimum.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MINSA',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Node {name: 'a'})-[:MINSA*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;


match (n)-[r:TYPE]->(m)
set r.weight=1.0/r.cost;

MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescence.minimum.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'weight',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'weight',
  writeProperty: 'MAXSA2',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Node {name: 'a'})-[:MAXSA2*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;

MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescence.maximum.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MAXSA',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Node {name: 'a'})-[:MAXSA*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;


MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescence.kmin.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMINSA',
  weightWriteProperty: 'writeCost',
  k:4
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Node {name: 'a'})-[:KMINSA*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;


MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescence.kmax.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMAXSA',
  weightWriteProperty: 'writeCost',
  k:4
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Node {name: 'a'})-[:KMAXSA*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;


//---最小树形图测试  出度方向  销售链--------------------------------------------------------------------------------------------------------------------------------
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
			
MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.minimum.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MINSAR',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;       

MATCH path = (n:Node {name: 'a'})-[:MINSAR*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;			

MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.maximum.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MAXSAR',
  weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;    

MATCH path = (n:Node {name: 'a'})-[:MAXSAR*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;			  

MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.kmin.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMINSAR',
  weightWriteProperty: 'writeCost',
  k:4
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;     

MATCH path = (n:Node {name: 'a'})-[:KMINSAR*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;		    


MATCH (n:Node{name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.kmax.write({
  nodeProjection: 'Node',
  relationshipProjection: {
    TYPE: {
      type: 'TYPE',
      properties: 'cost',
      orientation: 'NATURAL'   
   }  },
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMAXSAR',
  weightWriteProperty: 'writeCost',
  k:4
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN createMillis,computeMillis, writeMillis, effectiveNodeCount;     

MATCH path = (n:Node {name: 'a'})-[:KMAXSAR*]-()
WITH relationships(path) AS rels
UNWIND rels AS rel
WITH DISTINCT rel AS rel
RETURN startNode(rel) as source, endNode(rel) AS destination, rel;		    


:use test
create or replace database test
call db.schema.visualization
  