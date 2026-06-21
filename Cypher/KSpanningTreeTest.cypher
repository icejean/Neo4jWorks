//验证GDS安装
return gds.version()

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
       
CALL gds.graph.project(
  'graph',
  'Place',
  {
    LINK: {
      type: 'LINK',
      properties: 'cost',
      orientation: 'UNDIRECTED'
    }
  }
)       


MATCH (n:Place {name: 'A'})
CALL gds.alpha.spanningTree.minimum.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MINST',
  weightWriteProperty: 'writeCost'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;

MATCH (n:Place {name: 'A'})
CALL gds.alpha.spanningTree.maximum.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MAXST',
  weightWriteProperty: 'writeCost'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;



MATCH (n:Place{name: 'A'})
CALL gds.alpha.spanningTree.mykmin.write('graph', {
  k: 4,
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  weightWriteProperty: 'cost',
  writeProperty:'KMINST'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis,computeMillis,writeMillis, effectiveNodeCount;


MATCH (n:Place{name: 'A'})
CALL gds.alpha.spanningTree.mykmax.write('graph', {
  k: 4,
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  weightWriteProperty: 'cost',
  writeProperty:'KMAXST'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis,computeMillis,writeMillis, effectiveNodeCount;


// 原实现最小生成树属性写到结点上，而不是写到边上，所以结果提取无法提取构成最小生成树的边
// k=2、4 时完全不对
MATCH (n:Place{name: 'A'})
CALL gds.alpha.spanningTree.kmin.write('graph', {
  k: 3,
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty:'kminst'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis,computeMillis,writeMillis, effectiveNodeCount;


// 没有结果，完全不对
MATCH (n:Place{id: 'D'})
CALL gds.alpha.spanningTree.kmax.write('graph', {
  k: 3,
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty:'kminst'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis,computeMillis,writeMillis, effectiveNodeCount;

match (n:Place)-[r]-(m:Place) return n,r,m;


MATCH (n:Place)
WITH n.id AS Place, n.kminst AS Partition, count(*) AS count
WHERE count = 3
RETURN Place, Partition

MATCH (n:Place)
WITH n.kminst AS Partition, count(n.kminst) AS count
where count =3
match path = (n:Place)-[r:LINK]-(m:Place)
WHERE ALL( node IN nodes(path) where node.kminst = Partition)
with path, relationships(path) as links
UNWIND links AS link
return distinct link;

match (n)-[r]->(m) return n,r,m;


CALL gds.graph.drop( 'graph');





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


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescence.minimum.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MINSA',
  weightWriteProperty: 'cost'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescence.kmin.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMINSA',
  weightWriteProperty: 'cost',
  k: 4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescence.maximum.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MAXSA',
  weightWriteProperty: 'cost'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescence.kmax.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMAXSA',
  weightWriteProperty: 'cost',
  k: 4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


match (n)-[r]->(m) return n,r,m;



//---最小树形图测试  出度方向  销售链--------------------------------------------------------------------------------------------------------------------------------

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


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.minimum.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MINSA',
  weightWriteProperty: 'cost'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.kmin.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMINSA',
  weightWriteProperty: 'cost',
  k: 4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.maximum.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'MAXSA',
  weightWriteProperty: 'cost'
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


MATCH (n:Node {name: 'a'})
CALL gds.alpha.spanningArborescenceReverse.kmax.write('graph', {
  startNodeId: id(n),
  relationshipWeightProperty: 'cost',
  writeProperty: 'KMAXSA',
  weightWriteProperty: 'cost',
  k: 4
})
YIELD preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN preProcessingMillis, computeMillis, writeMillis, effectiveNodeCount;


match (n)-[r]->(m) return n,r,m;


//查找procedure
call dbms.procedures() yield name,signature,description,mode
with name,signature,description,mode
where name contains "Arborescence" or name contains "mykm"
return name,signature,description,mode
order by name

