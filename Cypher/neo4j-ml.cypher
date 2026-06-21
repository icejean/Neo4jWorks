//录入引用数据库
// Create constraints
CREATE CONSTRAINT ON (a:Article) ASSERT a.index IS UNIQUE;
CREATE CONSTRAINT ON (a:Author) ASSERT a.name IS UNIQUE;
CREATE CONSTRAINT ON (v:Venue) ASSERT v.name IS UNIQUE;
// Import data from JSON files using the APOC library, // 3650962 ms for all, 38232 ms for subset
CALL apoc.periodic.iterate(
  'UNWIND ["dblp-ref-0.json", "dblp-ref-1.json", "dblp-ref-2.json", "dblp-ref-3.json"] AS file
   CALL apoc.load.json("file:///D:/temp/data/dblp-ref/" + file)
   YIELD value WITH value
   WHERE value.venue IN ["Lecture Notes in Computer Science", "Communications of The ACM",
                         "international conference on software engineering",
                         "advances in computing and communications"]   
   RETURN value',
  'MERGE (a:Article {index:value.id})
   SET a += apoc.map.clean(value,["id","authors","references", "venue"],[0])
   WITH a, value.authors as authors, value.references AS citations, value.venue AS venue
   MERGE (v:Venue {name: venue})
   MERGE (a)-[:VENUE]->(v)
   FOREACH(author in authors | 
     MERGE (b:Author{name:author})
     MERGE (a)-[:AUTHOR]->(b))
   FOREACH(citation in citations | 
     MERGE (cited:Article {index:citation})
     MERGE (a)-[:CITED]->(cited))', 
   {batchSize: 1000, iterateList: true});


//搭建共同作者图, Set 465672 properties, created 155224 relationships, completed after 3535 ms.
// tag::co-author[]
MATCH (a1)<-[:AUTHOR]-(paper)-[:AUTHOR]->(a2:Author)
WITH a1, a2, paper
ORDER BY a1, paper.year
WITH a1, a2, collect(paper)[0].year AS year, count(*) AS collaborations
MERGE (a1)-[coauthor:CO_AUTHOR {year: year}]-(a2)
SET coauthor.collaborations = collaborations;
// end::co-author[]


match (n:AUTHOR)-[r:CO_AUTHOR]->(m:AUTHOR) return n,r,m limit 50;

match (article:Article) where article.year is not null
return article.year as year, count(*) as count
order by year;

match (article:Article) where article.year is not null
return article.year<2006 as train, count(*) as count;

//训练子图, Set 81096 properties, created 81096 relationships, completed after 1584 ms.

MATCH (a)-[r:CO_AUTHOR]->(b) 
WHERE r.year < 2006
MERGE (a)-[:CO_AUTHOR_EARLY {year: r.year}]-(b);

//测试子图, Set 74128 properties, created 74128 relationships, completed after 1061 ms.

MATCH (a)-[r:CO_AUTHOR]->(b) 
WHERE r.year >= 2006
MERGE (a)-[:CO_AUTHOR_LATE {year: r.year}]-(b);


// negative examples = (# nodes)^2 - (# relationships) - (# nodes)

//将彼此之间相距2至3跳的节点进行配对
MATCH (author:Author)
WHERE (author)-[:CO_AUTHOR_EARLY]-()
MATCH (author)-[:CO_AUTHOR_EARLY*2..3]-(other)
WHERE not((author)-[:CO_AUTHOR_EARLY]-(other))
RETURN id(author) AS node1, id(other) AS node2;

//训练集
//三角计数
CALL gds.triangleCount.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR_EARLY:{ type:'CO_AUTHOR_EARLY',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  writeProperty:'trianglesTrain'
  });
  
//聚类系数
CALL gds.localClusteringCoefficient.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR_EARLY:{ type:'CO_AUTHOR_EARLY',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  writeProperty: 'coefficientTrain'
})
YIELD averageClusteringCoefficient, nodeCount;

//测试集
//三角计数
CALL gds.triangleCount.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR:{ type:'CO_AUTHOR',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  writeProperty:'trianglesTest'
  });
  
//聚类系数
CALL gds.localClusteringCoefficient.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR:{ type:'CO_AUTHOR',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  writeProperty: 'coefficientTest'
})
YIELD averageClusteringCoefficient, nodeCount;

//PageRank
CALL gds.pageRank.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR_EARLY:{ type:'CO_AUTHOR_EARLY',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  writeProperty: 'pagerankTrain'
})
YIELD nodePropertiesWritten, ranIterations;

CALL gds.pageRank.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR:{ type:'CO_AUTHOR',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  writeProperty: 'pagerankTest'
})
YIELD nodePropertiesWritten, ranIterations;

//Label Propagation algorithm (LPA)， directed & weighted
CALL gds.labelPropagation.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR_EARLY:{ type:'CO_AUTHOR_EARLY',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
 writeProperty: 'partitionTrain'
})
YIELD communityCount, ranIterations, didConverge;

CALL gds.labelPropagation.write({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR:{ type:'CO_AUTHOR',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
 writeProperty: 'partitionTest'
})
YIELD communityCount, ranIterations, didConverge;

// Louvain
CALL gds.louvain.stream({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR_EARLY:{ type:'CO_AUTHOR_EARLY',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  includeIntermediateCommunities: true
})
YIELD nodeId, communityId, intermediateCommunityIds
with gds.util.asNode(nodeId) as node, communityId, intermediateCommunityIds
set node.louvainTrain = communityId, node.intermediateTrain= intermediateCommunityIds;

CALL gds.louvain.stream({
  nodeProjection:'Author',
  relationshipProjection:{
     CO_AUTHOR:{ type:'CO_AUTHOR',
             orientation:'UNDIRECTED'  //NATURAL, REVERSE, UNDIRECTED 
  }},
  includeIntermediateCommunities: true
})
YIELD nodeId, communityId, intermediateCommunityIds
with gds.util.asNode(nodeId) as node, communityId, intermediateCommunityIds
set node.louvainTest = communityId, node.intermediateTest= intermediateCommunityIds;


