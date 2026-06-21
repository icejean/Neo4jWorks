//Degree Centrality
// 可用于计算客户数或供应商数量
//Degree Centrality algorithm sample
CALL gds.alpha.degree.write(configuration: Map)
YIELD nodes, createMillis, computeMillis, writeMillis, writeProperty, centralityDistribution


CREATE (alice:User {name: 'Alice'}),
       (bridget:User {name: 'Bridget'}),
       (charles:User {name: 'Charles'}),
       (doug:User {name: 'Doug'}),
       (mark:User {name: 'Mark'}),
       (michael:User {name: 'Michael'}),
       (alice)-[:FOLLOWS]->(doug),
       (alice)-[:FOLLOWS]->(bridget),
       (alice)-[:FOLLOWS]->(charles),
       (mark)-[:FOLLOWS]->(doug),
       (mark)-[:FOLLOWS]->(michael),
       (bridget)-[:FOLLOWS]->(doug),
       (charles)-[:FOLLOWS]->(doug),
       (michael)-[:FOLLOWS]->(doug)


CALL gds.alpha.degree.stream({
  nodeProjection: 'User',
  relationshipProjection: {
    FOLLOWS: {
      type: 'FOLLOWS',
      orientation: 'REVERSE'
    }
  }
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score AS followers
ORDER BY followers DESC

CALL gds.alpha.degree.write({
  nodeProjection: 'User',
  relationshipProjection: {
    FOLLOWS: {
      type: 'FOLLOWS',
      orientation: 'REVERSE'
    }
  },
  writeProperty: 'followers'
})      

CALL gds.alpha.degree.stream({
  nodeProjection: 'User',
  relationshipProjection: 'FOLLOWS'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score AS followers
ORDER BY followers DESC

CALL gds.alpha.degree.write({
  nodeProjection: 'User',
  relationshipProjection: 'FOLLOWS',
  writeProperty: 'followers'
})


//Weighted Degree Centrality algorithm sample
//可用于计算购买额或销售额
CREATE (alice:User {name:'Alice'}),
       (bridget:User {name:'Bridget'}),
       (charles:User {name:'Charles'}),
       (doug:User {name:'Doug'}),
       (mark:User {name:'Mark'}),
       (michael:User {name:'Michael'}),
       (alice)-[:FOLLOWS {score: 1}]->(doug),
       (alice)-[:FOLLOWS {score: 2}]->(bridget),
       (alice)-[:FOLLOWS {score: 5}]->(charles),
       (mark)-[:FOLLOWS {score: 1.5}]->(doug),
       (mark)-[:FOLLOWS {score: 4.5}]->(michael),
       (bridget)-[:FOLLOWS {score: 1.5}]->(doug),
       (charles)-[:FOLLOWS {score: 2}]->(doug),
       (michael)-[:FOLLOWS {score: 1.5}]->(doug) 
       
CALL gds.alpha.degree.stream({
   nodeProjection: 'User',
   relationshipProjection: {
       FOLLOWS: {
           type: 'FOLLOWS',
           orientation: 'REVERSE',
           properties: 'score'
       }
   },
   relationshipWeightProperty: 'score'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score AS weightedFollowers
ORDER BY weightedFollowers DESC

CALL gds.alpha.degree.write({
   nodeProjection: 'User',
   relationshipProjection: {
       FOLLOWS: {
           type: 'FOLLOWS',
           orientation: 'REVERSE',
           properties: 'score'
       }
   },
   relationshipWeightProperty: 'score',
   writeProperty: 'weightedFollowers'
})
YIELD nodes, writeProperty

//Cypher projection
CALL gds.alpha.degree.write({
  nodeQuery: 'MATCH (u:User) RETURN id(u) AS id',
  relationshipQuery: 'MATCH (u1:User)<-[:FOLLOWS]-(u2:User) RETURN id(u1) AS source, id(u2) AS target',
  writeProperty: 'followers'
})

CALL gds.alpha.degree.write({
  nodeQuery: 'MATCH (u:User) RETURN id(u) AS id',
  relationshipQuery: 'MATCH (u1:User)-[:FOLLOWS]->(u2:User) RETURN id(u1) AS source, id(u2) AS target',
  writeProperty: 'followers'
})


//Closeness Centrality  
// 接近中心性，适用于连通图，对于非连通图，计算的是在连通的子图中的接近中心性，见后面的例子
CALL gds.alpha.closeness.write(configuration: Map)
YIELD nodes, createMillis, computeMillis, writeMillis, centralityDistribution

CALL gds.alpha.closeness.stream(configuration: Map)
YIELD nodeId, centrality

//Closeness Centrality algorithm sample
CREATE (a:Node{id:"A"}),
       (b:Node{id:"B"}),
       (c:Node{id:"C"}),
       (d:Node{id:"D"}),
       (e:Node{id:"E"}),
       (a)-[:LINK]->(b),
       (b)-[:LINK]->(a),
       (b)-[:LINK]->(c),
       (c)-[:LINK]->(b),
       (c)-[:LINK]->(d),
       (d)-[:LINK]->(c),
       (d)-[:LINK]->(e),
       (e)-[:LINK]->(d);
       
CALL gds.alpha.closeness.stream({
  nodeProjection: 'Node',
  relationshipProjection: 'LINK'
})
YIELD nodeId, centrality
RETURN gds.util.asNode(nodeId).id AS user, centrality
ORDER BY centrality DESC

CALL gds.alpha.closeness.write({
  nodeProjection: 'Node',
  relationshipProjection: 'LINK',
  writeProperty: 'centrality'
}) YIELD nodes, writeProperty

CALL gds.alpha.closeness.write({
  nodeQuery: 'MATCH (p:Node) RETURN id(p) AS id',
  relationshipQuery: 'MATCH (p1:Node)-[:LINK]->(p2:Node) RETURN id(p1) AS source, id(p2) AS target'
}) YIELD nodes, writeProperty


//Harmonic Centrality algorithm sample
// 调和中心性，适用于非连通图，计算在全图中的接近中心性。
CREATE (a:Node{id:"A"}),
       (b:Node{id:"B"}),
       (c:Node{id:"C"}),
       (d:Node{id:"D"}),
       (e:Node{id:"E"}),
       (a)-[:LINK]->(b),
       (b)-[:LINK]->(c),
       (d)-[:LINK]->(e);
       
// 计算在连通子图中的接近中心性      
CALL gds.alpha.closeness.stream({
  nodeProjection: 'Node',
  relationshipProjection: 'LINK'
})
YIELD nodeId, centrality
RETURN gds.util.asNode(nodeId).id AS user, centrality
ORDER BY centrality DESC       
       
CALL gds.alpha.closeness.harmonic.stream({
  nodeProjection: 'Node',
  relationshipProjection: 'LINK'
})
YIELD nodeId, centrality
RETURN gds.util.asNode(nodeId).id AS user, centrality
ORDER BY centrality DESC

CALL gds.alpha.closeness.harmonic.write({
  nodeProjection: 'Node',
  relationshipProjection: 'LINK',
  writeProperty: 'centrality'
}) YIELD nodes, writeProperty



//Betweenness Centrality
CALL gds.betweenness.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  score: Float
  
CALL gds.betweenness.write(
  configuration: Map
)
YIELD
  centralityDistribution: Map,
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  nodePropertiesWritten: Integer,
  configuration: Map
  
CREATE
  (alice:User {name: 'Alice'}),
  (bob:User {name: 'Bob'}),
  (carol:User {name: 'Carol'}),
  (dan:User {name: 'Dan'}),
  (eve:User {name: 'Eve'}),
  (frank:User {name: 'Frank'}),
  (gale:User {name: 'Gale'}),

  (alice)-[:FOLLOWS]->(carol),
  (bob)-[:FOLLOWS]->(carol),
  (carol)-[:FOLLOWS]->(dan),
  (carol)-[:FOLLOWS]->(eve),
  (dan)-[:FOLLOWS]->(frank),
  (eve)-[:FOLLOWS]->(frank),
  (frank)-[:FOLLOWS]->(gale);

// Create an in memory graph, not written to the disk  
CALL gds.graph.create('myGraph', 'User', 'FOLLOWS')

CALL gds.betweenness.write.estimate('myGraph', { writeProperty: 'betweenness' })
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.betweenness.write.estimate('myGraph', { writeProperty: 'betweenness', concurrency: 1 })
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.betweenness.stream('myGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY name ASC

CALL gds.betweenness.stats('myGraph')
YIELD centralityDistribution
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore

// Written to in-memory graph
CALL gds.betweenness.mutate('myGraph', { mutateProperty: 'betweenness' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten             

// Written to Noe4j database
CALL gds.betweenness.write('myGraph', { writeProperty: 'betweenness' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten

//RA-Brandes算法，结合了随机抽样(samplingSeed)与度抽样，根据文档，出度大的节点被抽样选中的几率更高。
// 每次只抽样samplingSize个节点的子图计算，但计算的结果覆盖全图所有的节点？具体抽样及计算规则在线文档并没有详细说明。
// 但结果中每个节点都返回了中间中心性的近似值。
CALL gds.betweenness.stream('myGraph', {samplingSize: 2, samplingSeed: 0})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY name ASC

//无向图
CALL gds.graph.create('myUndirectedGraph', 'User', {FOLLOWS: {orientation: 'UNDIRECTED'}})

CALL gds.betweenness.stream('myUndirectedGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY name ASC


//PageRank
// 可用于上下游产业链影响力的分析，用交易金额为权重计算PageRank，然后用PageRank为权重计算影响路径，
// 作为供应链、销售链上节点重要性的评估，与直接用销售金额求得的主要供应链、销售链比较，研究一下。
CALL gds.pageRank.stream(
  graphName: String,
  configuration: Map
)
YIELD
  nodeId: Integer,
  score: Float
  
CALL gds.pageRank.write(
  configuration: Map
)
YIELD
  nodePropertiesWritten: Integer,
  ranIterations: Integer,
  didConverge: Boolean,
  createMillis: Integer,
  computeMillis: Integer,
  writeMillis: Integer,
  centralityDistribution: Map,
  configuration: Map
  
CREATE
  (home:Page {name:'Home'}),
  (about:Page {name:'About'}),
  (product:Page {name:'Product'}),
  (links:Page {name:'Links'}),
  (a:Page {name:'Site A'}),
  (b:Page {name:'Site B'}),
  (c:Page {name:'Site C'}),
  (d:Page {name:'Site D'}),

  (home)-[:LINKS {weight: 0.2}]->(about),
  (home)-[:LINKS {weight: 0.2}]->(links),
  (home)-[:LINKS {weight: 0.6}]->(product),
  (about)-[:LINKS {weight: 1.0}]->(home),
  (product)-[:LINKS {weight: 1.0}]->(home),
  (a)-[:LINKS {weight: 1.0}]->(home),
  (b)-[:LINKS {weight: 1.0}]->(home),
  (c)-[:LINKS {weight: 1.0}]->(home),
  (d)-[:LINKS {weight: 1.0}]->(home),
  (links)-[:LINKS {weight: 0.8}]->(home),
  (links)-[:LINKS {weight: 0.05}]->(a),
  (links)-[:LINKS {weight: 0.05}]->(b),
  (links)-[:LINKS {weight: 0.05}]->(c),
  (links)-[:LINKS {weight: 0.05}]->(d);

// The graph is created in memory graph catalog  
CALL gds.graph.create(
  'myGraph',
  'Page',
  'LINKS',
  {
    relationshipProperties: 'weight'
  }
)

// 参数都是默认值
CALL gds.pageRank.write.estimate('myGraph', {
  writeProperty: 'pageRank',
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeCount, relationshipCount, bytesMin, bytesMax, requiredMemory

CALL gds.pageRank.stream('myGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC, name ASC

CALL gds.pageRank.stats('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD centralityDistribution
RETURN centralityDistribution.max AS max


//变异模式，结果写入内存图中，在此基础上可以继续应用其它的图算法，即只是中间结果。
CALL gds.pageRank.mutate('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  mutateProperty: 'pagerank'
})
YIELD nodePropertiesWritten, ranIterations

CALL gds.pageRank.write('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  writeProperty: 'pagerank'
})
YIELD nodePropertiesWritten, ranIterations

//加权PageRank，节点的rank传递给邻接节点前先乘以边（出度）的权重，然后除以该节点所有出度权重的和。
CALL gds.pageRank.stream('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC, name ASC

//收敛边界，当两次迭代之间，节点rank的差异小于tolerance的设定，则认为算法收敛，迭代结束。
//此参数没有设定时使用的是默认值0.0000001。
CALL gds.pageRank.stream('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  tolerance: 0.1
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC, name ASC

//阻尼系数d, 0<=d<1, d越大则发生 Rank Sink或 Spider Trap的机会越高，算法可能震荡而不能收敛，默认0.85。
// d越小，则最终结果各节点的rank都接近1，因而不能反映图上节点的实际影响力。
//d的定义，从当前节点随机跳转到邻接节点的概率，d越小，节点影响力的随机性越大。
CALL gds.pageRank.stream('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.05
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC, name ASC

//个性化PageRank，加入偏好后(sourceNodes，每次随机跳转都返回该节点集)的PageRank，
//常用于推荐系统，可以考虑用于产业链匹配，推荐供需方对接的系统。
MATCH (siteA:Page {name: 'Site A'})
CALL gds.pageRank.stream('myGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  sourceNodes: [siteA]
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS name, score
ORDER BY score DESC, name ASC

//ArticleRank, unweighted
// 文章引用PageRank, 非加权图，不适用于发票交易网络分析。
// AR(A) = (1-d) + d * C(AVG) * (AR(T1)/(C(T1) + C(AVG)) + ... + AR(Tn)/(C(Tn) + C(AVG))
//where,

//    we assume that a page A has pages T1 to Tn which point to it (i.e., are citations).

//    d is a damping factor which can be set between 0 and 1. It is usually set to 0.85.

//    C(A) is defined as the number of links going out of page A.

//    C(AVG) is defined as the average number of links going out of all pages.

CREATE
  (paper0:Paper {name:'Paper 0'}),
  (paper1:Paper {name:'Paper 1'}),
  (paper2:Paper {name:'Paper 2'}),
  (paper3:Paper {name:'Paper 3'}),
  (paper4:Paper {name:'Paper 4'}),
  (paper5:Paper {name:'Paper 5'}),
  (paper6:Paper {name:'Paper 6'}),

  (paper1)-[:CITES]->(paper0),

  (paper2)-[:CITES]->(paper0),
  (paper2)-[:CITES]->(paper1),

  (paper3)-[:CITES]->(paper0),
  (paper3)-[:CITES]->(paper1),
  (paper3)-[:CITES]->(paper2),

  (paper4)-[:CITES]->(paper0),
  (paper4)-[:CITES]->(paper1),
  (paper4)-[:CITES]->(paper2),
  (paper4)-[:CITES]->(paper3),

  (paper5)-[:CITES]->(paper1),
  (paper5)-[:CITES]->(paper4),

  (paper6)-[:CITES]->(paper1),
  (paper6)-[:CITES]->(paper4);
  
CALL gds.alpha.articleRank.stream({
  nodeProjection: 'Paper',
  relationshipProjection: 'CITES',
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS Name, score as ArticleRank
ORDER BY score DESC

CALL gds.alpha.articleRank.write({
  nodeProjection: 'Paper',
  relationshipProjection: 'CITES',
  maxIterations:20, dampingFactor:0.85,
  writeProperty: "pagerank"
}) YIELD nodes
  

//unweighted
//Eigenvector Centrality is an algorithm that measures the transitive influence or connectivity of nodes.
//Eigenvector Centrality can be used in many of the same use cases as the Page Rank algorithm
// 特征向量中心性，衡量节点重要性的传递，适用于一些PageRank算法场景，非加权图不适用于发票交易网络分析。
CREATE (home:Page {name:'Home'}),
       (about:Page {name:'About'}),
       (product:Page {name:'Product'}),
       (links:Page {name:'Links'}),
       (a:Page {name:'Site A'}),
       (b:Page {name:'Site B'}),
       (c:Page {name:'Site C'}),
       (d:Page {name:'Site D'}),
       (home)-[:LINKS]->(about),
       (about)-[:LINKS]->(home),
       (product)-[:LINKS]->(home),
       (home)-[:LINKS]->(product),
       (links)-[:LINKS]->(home),
       (home)-[:LINKS]->(links),
       (links)-[:LINKS]->(a),
       (a)-[:LINKS]->(home),
       (links)-[:LINKS]->(b),
       (b)-[:LINKS]->(home),
       (links)-[:LINKS]->(c),
       (c)-[:LINKS]->(home),
       (links)-[:LINKS]->(d),
       (d)-[:LINKS]->(home)
       
CALL gds.alpha.eigenvector.stream({
  nodeProjection: 'Page',
  relationshipProjection: 'LINKS'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS page, score
ORDER BY score DESC

CALL gds.alpha.eigenvector.write({
  nodeProjection: 'Page',
  relationshipProjection: 'LINKS',
  writeProperty: 'eigenvector'
})
YIELD nodes, iterations, dampingFactor, writeProperty

//max, l1norm, l2norm
CALL gds.alpha.eigenvector.stream({
  nodeProjection: 'Page',
  relationshipProjection: 'LINKS',
  normalization: 'max'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS page, score
ORDER BY score DESC       

//unweighted， 非加权图算法不适用于发票交易网络分析。
//The Hyperlink-Induced Topic Search (HITS) is a link analysis algorithm that rates nodes based on two scores, 
//a hub score and an authority score. The authority score estimates the importance of the node within the network.
// The hub score estimates the value of its relationships to other nodes. The GDS implementation is based on 
//the Authoritative Sources in a Hyperlinked Environment publication by Jon M. Kleinberg.
// auth rank衡量节点在全图中的重要性， hub rank衡量在相邻节点中的重要性。

CREATE
  (a:Website {name: 'A'}),
  (b:Website {name: 'B'}),
  (c:Website {name: 'C'}),
  (d:Website {name: 'D'}),
  (e:Website {name: 'E'}),
  (f:Website {name: 'F'}),
  (g:Website {name: 'G'}),
  (h:Website {name: 'H'}),
  (i:Website {name: 'I'}),

  (a)-[:LINK]->(b),
  (a)-[:LINK]->(c),
  (a)-[:LINK]->(d),
  (b)-[:LINK]->(c),
  (b)-[:LINK]->(d),
  (c)-[:LINK]->(d),

  (e)-[:LINK]->(b),
  (e)-[:LINK]->(d),
  (e)-[:LINK]->(f),
  (e)-[:LINK]->(h),

  (f)-[:LINK]->(g),
  (f)-[:LINK]->(i),
  (f)-[:LINK]->(h),
  (g)-[:LINK]->(h),
  (g)-[:LINK]->(i),
  (h)-[:LINK]->(i);
  
CALL gds.graph.create(
  'myGraph',
  'Website',
  'LINK'
);

CALL gds.alpha.hits.stream('myGraph', {hitsIterations: 20})
YIELD nodeId, values
RETURN gds.util.asNode(nodeId).name AS Name, values.auth AS auth, values.hub as hub
ORDER BY Name ASC

  

// Load data
LOAD CSV WITH HEADERS FROM "file:///E:/Neo4j/0636920233145-master/data/social-nodes.csv"  AS row
MERGE (:User {id: row.id})

LOAD CSV WITH HEADERS FROM "file:///E:/Neo4j/0636920233145-master/data/social-relationships.csv" AS row
MATCH (source:User {id: row.src})
MATCH (destination:User {id: row.dst})
MERGE (source)-[:FOLLOWS]->(destination)      