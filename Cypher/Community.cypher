//Triangle Count, undirected
CALL gds.triangleCount.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  triangleCount: Integer
  
CALL gds.triangleCount.write(
  configuration: Map
)
YIELD
  globalTriangleCount: Integer,
  nodeCount: Integer,
  nodePropertiesWritten: Integer,
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  configuration: Map
  
CALL gds.alpha.triangles(
  graphName: String,
  configuration: Map
)
YIELD nodeA, nodeB, nodeC

CREATE
  (alice:Person {name: 'Alice'}),
  (michael:Person {name: 'Michael'}),
  (karin:Person {name: 'Karin'}),
  (chris:Person {name: 'Chris'}),
  (will:Person {name: 'Will'}),
  (mark:Person {name: 'Mark'}),

  (michael)-[:KNOWS]->(karin),
  (michael)-[:KNOWS]->(chris),
  (will)-[:KNOWS]->(michael),
  (mark)-[:KNOWS]->(michael),
  (mark)-[:KNOWS]->(will),
  (alice)-[:KNOWS]->(michael),
  (will)-[:KNOWS]->(chris),
  (chris)-[:KNOWS]->(karin)
  
CALL gds.graph.create(
  'myGraph',
  'Person',
  {
    KNOWS: {
      orientation: 'UNDIRECTED'
    }
  }
)

CALL gds.triangleCount.write.estimate('myGraph', { writeProperty: 'triangleCount' })
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.triangleCount.stream('myGraph')
YIELD nodeId, triangleCount
RETURN gds.util.asNode(nodeId).name AS name, triangleCount
ORDER BY triangleCount DESC

CALL gds.triangleCount.stats('myGraph')
YIELD globalTriangleCount, nodeCount

CALL gds.triangleCount.mutate('myGraph', {
  mutateProperty: 'triangles'
})
YIELD globalTriangleCount, nodeCount

CALL gds.triangleCount.write('myGraph', {
  writeProperty: 'triangles'
})
YIELD globalTriangleCount, nodeCount

//度数超过 maxDegree的超级节点，triangleCount = -1
CALL gds.triangleCount.stream('myGraph', {
  maxDegree: 4
})
YIELD nodeId, triangleCount
RETURN gds.util.asNode(nodeId).name AS name, triangleCount
ORDER BY name ASC

CALL gds.alpha.triangles('myGraph')
YIELD nodeA, nodeB, nodeC
RETURN
  gds.util.asNode(nodeA).name AS nodeA,
  gds.util.asNode(nodeB).name AS nodeB,
  gds.util.asNode(nodeC).name AS nodeC


//the Local Clustering Coefficient algorithm, base on triangel count algorithn, undirected
CALL gds.localClusteringCoefficient.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  localClusteringCoefficient: Double
  
CALL gds.localClusteringCoefficient.write(
  configuration: Map
)
YIELD
  averageClusteringCoefficient: Double,
  nodeCount: Integer,
  nodePropertiesWritten: Integer,
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  configuration: Map
  
CREATE
  (alice:Person {name: 'Alice'}),
  (michael:Person {name: 'Michael'}),
  (karin:Person {name: 'Karin'}),
  (chris:Person {name: 'Chris'}),
  (will:Person {name: 'Will'}),
  (mark:Person {name: 'Mark'}),

  (michael)-[:KNOWS]->(karin),
  (michael)-[:KNOWS]->(chris),
  (will)-[:KNOWS]->(michael),
  (mark)-[:KNOWS]->(michael),
  (mark)-[:KNOWS]->(will),
  (alice)-[:KNOWS]->(michael),
  (will)-[:KNOWS]->(chris),
  (chris)-[:KNOWS]->(karin)
  
CALL gds.graph.create(
  'myGraph',
  'Person',
  {
    KNOWS: {
      orientation: 'UNDIRECTED'
    }
  }
)

CALL gds.localClusteringCoefficient.write.estimate('myGraph', {
  writeProperty: 'localClusteringCoefficient'
})
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.localClusteringCoefficient.stream('myGraph')
YIELD nodeId, localClusteringCoefficient
RETURN gds.util.asNode(nodeId).name AS name, localClusteringCoefficient
ORDER BY localClusteringCoefficient DESC

CALL gds.localClusteringCoefficient.stats('myGraph')
YIELD averageClusteringCoefficient, nodeCount

CALL gds.localClusteringCoefficient.mutate('myGraph', {
  mutateProperty: 'localClusteringCoefficient'
})
YIELD averageClusteringCoefficient, nodeCount

CALL gds.localClusteringCoefficient.write('myGraph', {
  writeProperty: 'localClusteringCoefficient'
})
YIELD averageClusteringCoefficient, nodeCount

CALL gds.triangleCount.mutate('myGraph', {
  mutateProperty: 'triangles'
})

CALL gds.localClusteringCoefficient.stream('myGraph', {
  triangleCountProperty: 'triangles'
})
YIELD nodeId, localClusteringCoefficient
RETURN gds.util.asNode(nodeId).name AS name, localClusteringCoefficient
ORDER BY localClusteringCoefficient DESC
  

//Strongly Connected Components (SCC), directed
//连通性分析一般用于早期分析网络的结构。
//虚开网络一般会形成资金环流，强连通分量算法可以找出所有形成环流的最大节点子集，可以在虚开风险分析中应用。
CALL gds.alpha.scc.write(graphName: String|Map, configuration: Map)
YIELD createMillis, computeMillis, writeMillis, setCount, maxSetSize, minSetSize

CALL gds.alpha.scc.stream(graphName: String, configuration: Map)
YIELD nodeId, componentId

CREATE (nAlice:User {name:'Alice'})
CREATE (nBridget:User {name:'Bridget'})
CREATE (nCharles:User {name:'Charles'})
CREATE (nDoug:User {name:'Doug'})
CREATE (nMark:User {name:'Mark'})
CREATE (nMichael:User {name:'Michael'})

CREATE (nAlice)-[:FOLLOW]->(nBridget)
CREATE (nAlice)-[:FOLLOW]->(nCharles)
CREATE (nMark)-[:FOLLOW]->(nDoug)
CREATE (nMark)-[:FOLLOW]->(nMichael)
CREATE (nBridget)-[:FOLLOW]->(nMichael)
CREATE (nDoug)-[:FOLLOW]->(nMark)
CREATE (nMichael)-[:FOLLOW]->(nAlice)
CREATE (nAlice)-[:FOLLOW]->(nMichael)
CREATE (nBridget)-[:FOLLOW]->(nAlice)
CREATE (nMichael)-[:FOLLOW]->(nBridget);

CALL gds.alpha.scc.write({
  nodeProjection: 'User',
  relationshipProjection: 'FOLLOW',
  writeProperty: 'componentId'
})
YIELD setCount, maxSetSize, minSetSize;

CALL gds.alpha.scc.stream({
  nodeProjection: 'User',
  relationshipProjection: 'FOLLOW'
})
YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).name AS Name, componentId AS Component
ORDER BY Component DESC

MATCH (u:User)
RETURN u.componentId AS Component, count(*) AS ComponentSize
ORDER BY ComponentSize DESC
LIMIT 1

CALL gds.alpha.scc.stream({
  nodeQuery: 'MATCH (u:User) RETURN id(u) AS id',
  relationshipQuery: 'MATCH (u1:User)-[:FOLLOW]->(u2:User) RETURN id(u1) AS source, id(u2) AS target' })
YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).name AS Name, componentId AS Component
ORDER BY Component DESC

//Weakly Connected Components (WCC), undirected
CALL gds.wcc.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  componentId: Integer
  
CALL gds.wcc.write(
  configuration: Map
)
YIELD
  componentCount: Integer,
  nodePropertiesWritten: Integer,
  relationshipPropertiesWritten: Integer,
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  postProcessingMillis: Integer,
  componentDistribution: Map,
  configuration: Map
  
CREATE
  (nAlice:User {name: 'Alice'}),
  (nBridget:User {name: 'Bridget'}),
  (nCharles:User {name: 'Charles'}),
  (nDoug:User {name: 'Doug'}),
  (nMark:User {name: 'Mark'}),
  (nMichael:User {name: 'Michael'}),

  (nAlice)-[:LINK {weight: 0.5}]->(nBridget),
  (nAlice)-[:LINK {weight: 4}]->(nCharles),
  (nMark)-[:LINK {weight: 1.1}]->(nDoug),
  (nMark)-[:LINK {weight: 2}]->(nMichael);
  
CALL gds.graph.create(
  'myGraph',
  'User',
  'LINK',
  {
    relationshipProperties: 'weight'
  }
)

CALL gds.wcc.write.estimate('myGraph', { writeProperty: 'component' })
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.wcc.stream('myGraph')
YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).name AS name, componentId
ORDER BY componentId, name

CALL gds.wcc.stats('myGraph')
YIELD componentCount

CALL gds.wcc.mutate('myGraph', { mutateProperty: 'componentId' })
YIELD nodePropertiesWritten, componentCount;

CALL gds.wcc.write('myGraph', { writeProperty: 'componentId' })
YIELD nodePropertiesWritten, componentCount;

//只有权重在阀值以上的边才被计算，如果权值缺失，默认置为0，没有defaultValue参数
CALL gds.wcc.stream('myGraph', {
  relationshipWeightProperty: 'weight',
  threshold: 1.0
}) YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).name AS Name, componentId AS ComponentId
ORDER BY ComponentId, Name

//Seeded components，在已有的分组上，对新增的节点分组，只写入分组有变化的节点
//step 1 
CALL gds.wcc.write('myGraph', {
  writeProperty: 'componentId',
  relationshipWeightProperty: 'weight',
  threshold: 1.0
})
YIELD nodePropertiesWritten, componentCount;

// step 2 add a new node
MATCH (b:User {name: 'Bridget'})
CREATE (b)-[:LINK {weight: 2.0}]->(new:User {name: 'Mats'})

// Step 3 create a graph in memory contain the componentId computed before
CALL gds.graph.create(
  'myGraph-seeded',
  'User',
  'LINK',
  {
    nodeProperties: 'componentId',
    relationshipProperties: 'weight'
  }
)

// step 4
CALL gds.wcc.stream('myGraph-seeded', {
  seedProperty: 'componentId',
  relationshipWeightProperty: 'weight',
  threshold: 1.0
}) YIELD nodeId, componentId
RETURN gds.util.asNode(nodeId).name AS name, componentId
ORDER BY componentId, name

// Step 5 write seeded component
CALL gds.wcc.write('myGraph-seeded', {
  seedProperty: 'componentId',
  writeProperty: 'componentId',
  relationshipWeightProperty: 'weight',
  threshold: 1.0
})
YIELD nodePropertiesWritten, componentCount;


//Label Propagation algorithm (LPA)， directed & weighted
CALL gds.labelPropagation.stream(
  graphName: String,
  configuration: Map
)
YIELD
    nodeId: Integer,
    communityId: Integer
    
CALL gds.labelPropagation.write(
  configuration: Map
)
YIELD
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  postProcessingMillis: Integer,
  nodePropertiesWritten: Integer,
  communityCount: Integer,
  ranIterations: Integer,
  didConverge: Boolean,
  communityDistribution: Map,
  configuration: Map
  
CREATE
  (alice:User {name: 'Alice', seed_label: 52}),
  (bridget:User {name: 'Bridget', seed_label: 21}),
  (charles:User {name: 'Charles', seed_label: 43}),
  (doug:User {name: 'Doug', seed_label: 21}),
  (mark:User {name: 'Mark', seed_label: 19}),
  (michael:User {name: 'Michael', seed_label: 52}),

  (alice)-[:FOLLOW {weight: 1}]->(bridget),
  (alice)-[:FOLLOW {weight: 10}]->(charles),
  (mark)-[:FOLLOW {weight: 1}]->(doug),
  (bridget)-[:FOLLOW {weight: 1}]->(michael),
  (doug)-[:FOLLOW {weight: 1}]->(mark),
  (michael)-[:FOLLOW {weight: 1}]->(alice),
  (alice)-[:FOLLOW {weight: 1}]->(michael),
  (bridget)-[:FOLLOW {weight: 1}]->(alice),
  (michael)-[:FOLLOW {weight: 1}]->(bridget),
  (charles)-[:FOLLOW {weight: 1}]->(doug)
  
CALL gds.graph.create(
    'myGraph',
    'User',
    'FOLLOW',
    {
        nodeProperties: 'seed_label',
        relationshipProperties: 'weight'
    }
)

CALL gds.labelPropagation.write.estimate('myGraph', { writeProperty: 'community' })
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.labelPropagation.stream('myGraph')
YIELD nodeId, communityId AS Community
RETURN gds.util.asNode(nodeId).name AS Name, Community
ORDER BY Community, Name

CALL gds.labelPropagation.stats('myGraph')
YIELD communityCount, ranIterations, didConverge

CALL gds.labelPropagation.mutate('myGraph', { mutateProperty: 'community' })
YIELD communityCount, ranIterations, didConverge

CALL gds.labelPropagation.write('myGraph', { writeProperty: 'community' })
YIELD communityCount, ranIterations, didConverge

//加权标签传播算法，如果指定了节点的权重nodeWeightProperty，则标签传播计算过程中，节点权重会乘以边的权重。
//此算法结合了节点权重与边权重，PageRank算法的结果可以应用于此。
CALL gds.labelPropagation.stream('myGraph', { relationshipWeightProperty: 'weight' })
YIELD nodeId, communityId AS Community
RETURN gds.util.asNode(nodeId).name AS Name, Community
ORDER BY Community, Name

//Seeded，当图更新后，比如加入了新的节点，用于更新分组的情况。
CALL gds.labelPropagation.stream('myGraph', { seedProperty: 'seed_label' })
YIELD nodeId, communityId AS Community
RETURN gds.util.asNode(nodeId).name AS Name, Community
ORDER BY Community, Name


//The Speaker-Listener Label Propagation Algorithm (SLLPA)，可以处理一个节点属于多个群组的情况。
CALL gds.alpha.sllpa.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  values: Map {
    communtiyIds: List of Integer
  }
  
CREATE
  (a:Person {name: 'Alice'}),
  (b:Person {name: 'Bob'}),
  (c:Person {name: 'Carol'}),
  (d:Person {name: 'Dave'}),
  (e:Person {name: 'Eve'}),
  (f:Person {name: 'Fredrick'}),
  (g:Person {name: 'Gary'}),
  (h:Person {name: 'Hilda'}),
  (i:Person {name: 'Ichabod'}),
  (j:Person {name: 'James'}),
  (k:Person {name: 'Khalid'}),

  (a)-[:KNOWS]->(b),
  (a)-[:KNOWS]->(c),
  (a)-[:KNOWS]->(d),
  (b)-[:KNOWS]->(c),
  (b)-[:KNOWS]->(d),
  (c)-[:KNOWS]->(d),

  (b)-[:KNOWS]->(e),
  (e)-[:KNOWS]->(f),
  (f)-[:KNOWS]->(g),
  (g)-[:KNOWS]->(h),

  (h)-[:KNOWS]->(i),
  (h)-[:KNOWS]->(j),
  (h)-[:KNOWS]->(k),
  (i)-[:KNOWS]->(j),
  (i)-[:KNOWS]->(k),
  (j)-[:KNOWS]->(k);
  
CALL gds.graph.create(
  'myGraph',
  'Person',
  {
    KNOWS: {
      orientation: 'UNDIRECTED'
    }
  }
);

CALL gds.alpha.sllpa.stream('myGraph', {maxIterations: 100, minAssociationStrength: 0.1})
YIELD nodeId, values
RETURN gds.util.asNode(nodeId).name AS Name, values.communityIds AS communityIds
  ORDER BY Name ASC
  


// Louvain algorithm, better for undirected，可以应用边的权重，没有应用节点的权重。
// 层次结构可以发现中间细粒度的社团，与标签传播算法可以互相补充。
CALL gds.louvain.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  communityId: Integer,
  intermediateCommunityIds: Integer[]
  
CALL gds.louvain.write(configuration: Map)
YIELD
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  postProcessingMillis: Integer,
  nodePropertiesWritten: Integer,
  communityCount: Integer,
  ranLevels: Integer,
  modularity: Float,
  modularities: Integer[],
  communityDistribution: Map,
  configuration: Map
  
CREATE
  (nAlice:User {name: 'Alice', seed: 42}),
  (nBridget:User {name: 'Bridget', seed: 42}),
  (nCharles:User {name: 'Charles', seed: 42}),
  (nDoug:User {name: 'Doug'}),
  (nMark:User {name: 'Mark'}),
  (nMichael:User {name: 'Michael'}),

  (nAlice)-[:LINK {weight: 1}]->(nBridget),
  (nAlice)-[:LINK {weight: 1}]->(nCharles),
  (nCharles)-[:LINK {weight: 1}]->(nBridget),

  (nAlice)-[:LINK {weight: 5}]->(nDoug),

  (nMark)-[:LINK {weight: 1}]->(nDoug),
  (nMark)-[:LINK {weight: 1}]->(nMichael),
  (nMichael)-[:LINK {weight: 1}]->(nMark);
  
CALL gds.graph.create(
    'myGraph',
    'User',
    {
        LINK: {
            orientation: 'UNDIRECTED'
        }
    },
    {
        nodeProperties: 'seed',
        relationshipProperties: 'weight'
    }
)

CALL gds.louvain.write.estimate('myGraph', { writeProperty: 'community' })
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.louvain.stream('myGraph')
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).name AS name, communityId, intermediateCommunityIds
ORDER BY name ASC

CALL gds.louvain.stats('myGraph')
YIELD communityCount

CALL gds.louvain.mutate('myGraph', { mutateProperty: 'communityId' })
YIELD communityCount, modularity, modularities

CALL gds.louvain.write('myGraph', { writeProperty: 'community' })
YIELD communityCount, modularity, modularities

CALL gds.louvain.stream('myGraph', { relationshipWeightProperty: 'weight' })
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).name AS name, communityId, intermediateCommunityIds
ORDER BY name ASC

CALL gds.louvain.stream('myGraph', { seedProperty: 'seed' })
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).name AS name, communityId, intermediateCommunityIds
ORDER BY name ASC

CREATE (a:Node {name: 'a'})
CREATE (b:Node {name: 'b'})
CREATE (c:Node {name: 'c'})
CREATE (d:Node {name: 'd'})
CREATE (e:Node {name: 'e'})
CREATE (f:Node {name: 'f'})
CREATE (g:Node {name: 'g'})
CREATE (h:Node {name: 'h'})
CREATE (i:Node {name: 'i'})
CREATE (j:Node {name: 'j'})
CREATE (k:Node {name: 'k'})
CREATE (l:Node {name: 'l'})
CREATE (m:Node {name: 'm'})
CREATE (n:Node {name: 'n'})
CREATE (x:Node {name: 'x'})

CREATE (a)-[:TYPE]->(b)
CREATE (a)-[:TYPE]->(d)
CREATE (a)-[:TYPE]->(f)
CREATE (b)-[:TYPE]->(d)
CREATE (b)-[:TYPE]->(x)
CREATE (b)-[:TYPE]->(g)
CREATE (b)-[:TYPE]->(e)
CREATE (c)-[:TYPE]->(x)
CREATE (c)-[:TYPE]->(f)
CREATE (d)-[:TYPE]->(k)
CREATE (e)-[:TYPE]->(x)
CREATE (e)-[:TYPE]->(f)
CREATE (e)-[:TYPE]->(h)
CREATE (f)-[:TYPE]->(g)
CREATE (g)-[:TYPE]->(h)
CREATE (h)-[:TYPE]->(i)
CREATE (h)-[:TYPE]->(j)
CREATE (i)-[:TYPE]->(k)
CREATE (j)-[:TYPE]->(k)
CREATE (j)-[:TYPE]->(m)
CREATE (j)-[:TYPE]->(n)
CREATE (k)-[:TYPE]->(m)
CREATE (k)-[:TYPE]->(l)
CREATE (l)-[:TYPE]->(n)
CREATE (m)-[:TYPE]->(n);

CALL gds.louvain.stream({
    nodeProjection: 'Node',
    relationshipProjection: {
        TYPE: {
            type: 'TYPE',
            orientation: 'undirected',
            aggregation: 'NONE'
        }
    },
    includeIntermediateCommunities: true
}) YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).name AS name, communityId, intermediateCommunityIds
ORDER BY name ASC


//The Modularity Optimization algorithm， 标准模块度算法。
CREATE
  (a:Person {name:'Alice'})
, (b:Person {name:'Bridget'})
, (c:Person {name:'Charles'})
, (d:Person {name:'Doug'})
, (e:Person {name:'Elton'})
, (f:Person {name:'Frank'})
, (a)-[:KNOWS {weight: 0.01}]->(b)
, (a)-[:KNOWS {weight: 5.0}]->(e)
, (a)-[:KNOWS {weight: 5.0}]->(f)
, (b)-[:KNOWS {weight: 5.0}]->(c)
, (b)-[:KNOWS {weight: 5.0}]->(d)
, (c)-[:KNOWS {weight: 0.01}]->(e)
, (f)-[:KNOWS {weight: 0.01}]->(d)

CALL gds.graph.create(
    'myGraph',
    'Person',
    {
        KNOWS: {
            type: 'KNOWS',
            orientation: 'UNDIRECTED',
            properties: ['weight']
        }
    })
    
CALL gds.beta.modularityOptimization.stream('myGraph', { relationshipWeightProperty: 'weight' })
YIELD nodeId, communityId
RETURN gds.util.asNode(nodeId).name AS name, communityId
ORDER BY name

CALL gds.beta.modularityOptimization.write('myGraph', { relationshipWeightProperty: 'weight', writeProperty: 'community' })
YIELD nodes, communityCount, ranIterations, didConverge

CALL gds.beta.modularityOptimization.mutate('myGraph', { relationshipWeightProperty: 'weight', mutateProperty: 'community' })
YIELD nodes, communityCount, ranIterations, didConverge


/
// the K-1 Coloring algorithm
CALL gds.beta.k1coloring.stream(graphName: String, {
  // additional configuration
})
YIELD nodeId, color

CREATE (alice:User {name: 'Alice'}),
       (bridget:User {name: 'Bridget'}),
       (charles:User {name: 'Charles'}),
       (doug:User {name: 'Doug'}),

       (alice)-[:LINK]->(bridget),
       (alice)-[:LINK]->(charles),
       (alice)-[:LINK]->(doug),
       (bridget)-[:LINK]->(charles)
       
CALL gds.graph.create(
    'myGraph',
    'User',
    {
        LINK : {
            orientation: 'UNDIRECTED'
        }
    }
)

CALL gds.graph.create('myGraph', 'Person', 'LIKES')

CALL gds.beta.k1coloring.stream('myGraph')
YIELD nodeId, color
RETURN gds.util.asNode(nodeId).name AS name, color
ORDER BY name

CALL gds.beta.k1coloring.write('myGraph', {writeProperty: 'color'})
YIELD nodeCount, colorCount, ranIterations, didConverge

CALL gds.beta.k1coloring.mutate('myGraph', {mutateProperty: 'color'})
YIELD nodeCount, colorCount, ranIterations, didConverge

CALL gds.beta.k1coloring.stats('myGraph')
YIELD nodeCount, colorCount, ranIterations, didConverge

                                             