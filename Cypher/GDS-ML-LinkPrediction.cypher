:use system
create or replace database dblp
:use dblp

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

//Remove articles that are missing a title
MATCH (a:Article)
WHERE not(exists(a.title))
DETACH DELETE a;

//Building a co-author graph
CALL apoc.periodic.iterate(
  "MATCH (a1)<-[:AUTHOR]-(paper)-[:AUTHOR]->(a2:Author)
   WITH a1, a2, paper
   ORDER BY a1, paper.year
   RETURN a1, a2, collect(paper)[0].year AS year, count(*) AS collaborations",
  "MERGE (a1)-[coauthor:CO_AUTHOR {year: year}]-(a2)
   SET coauthor.collaborations = collaborations",
  {batchSize: 100}
);

//Train and test datasets
CALL gds.graph.create(
  'linkpred',
  'Author',
  {
    CO_AUTHOR: {
      orientation: 'UNDIRECTED'
    }
  }
);

//create both train and test in-memory graphs, 
// Holdout 20% for test, 50% to 50% positive and negtive, reserve 80% for training and so on.
CALL gds.alpha.ml.splitRelationships.mutate('linkpred', {
  relationshipTypes: ['CO_AUTHOR'],
  remainingRelationshipType: 'CO_AUTHOR_REMAINING',
  holdoutRelationshipType: 'CO_AUTHOR_TESTGRAPH',
  holdoutFraction: 0.2
})
YIELD createMillis, computeMillis, mutateMillis, relationshipsWritten;

// Let's have a look
CALL gds.graph.streamRelationshipProperties('linkpred',['label'],['CO_AUTHOR_TESTGRAPH'])
YIELD sourceNodeId, targetNodeId, relationshipType, relationshipProperty, propertyValue
RETURN sourceNodeId, targetNodeId, relationshipType, relationshipProperty, propertyValue
LIMIT 10

// Hold out 80% * 20% = 16% for training, 50% to 50% positive and negtive, reserve 80% * 80% = 64% unused..
CALL gds.alpha.ml.splitRelationships.mutate('linkpred', {
  relationshipTypes: ['CO_AUTHOR_REMAINING'],
  remainingRelationshipType: 'CO_AUTHOR_IGNORED_FOR_TRAINING',
  holdoutRelationshipType: 'CO_AUTHOR_TRAINGRAPH',
  holdoutFraction: 0.8
})
YIELD createMillis, computeMillis, mutateMillis, relationshipsWritten;

// Let's have a look
CALL gds.graph.streamRelationshipProperties('linkpred',['label'],['CO_AUTHOR_TRAINGRAPH'])
YIELD sourceNodeId, targetNodeId, relationshipType, relationshipProperty, propertyValue
RETURN sourceNodeId, targetNodeId, relationshipType, relationshipProperty, propertyValue
LIMIT 10


//Feature Engineering
CALL gds.pageRank.mutate('linkpred',{
  maxIterations: 20,
  dampingFactor: 0.05,
  relationshipTypes: ["CO_AUTHOR"],
  mutateProperty: 'pagerank'
})
YIELD nodePropertiesWritten, mutateMillis, createMillis, computeMillis;

CALL gds.triangleCount.mutate('linkpred',{
  relationshipTypes: ["CO_AUTHOR"],
  mutateProperty: 'triangles'
})
YIELD nodePropertiesWritten, mutateMillis, nodeCount, createMillis, computeMillis;

return log10(80299)

// CO_AUTHOR_TRAINGRAPH is ncluded in CO_AUTHOR_REMAINING, should be CO_AUTHOR here
//    relationshipTypes: ["CO_AUTHOR_REMAINING"],
CALL gds.fastRP.mutate('linkpred', {
    embeddingDimension: 250,
    relationshipTypes: ["CO_AUTHOR"],
    iterationWeights: [0, 0, 1.0, 1.0],
    normalizationStrength:0.05,
    mutateProperty: 'fastRP_Embedding'
})
YIELD nodePropertiesWritten, mutateMillis, nodeCount, createMillis, computeMillis;

// CO_AUTHOR_TRAINGRAPH is ncluded in CO_AUTHOR_REMAINING, should be CO_AUTHOR here
//  relationshipTypes: ["CO_AUTHOR_REMAINING"],
//  propertyDimension: 45,
//  embeddingDimension: 250,

CALL gds.beta.fastRPExtended.mutate('linkpred', {
  propertyDimension: 5,
  embeddingDimension: 10,
  featureProperties: ["pagerank", "triangles"],
  relationshipTypes: ["CO_AUTHOR"],
  iterationWeights: [0, 0, 1.0, 1.0],
  normalizationStrength:0.05,
  mutateProperty: 'fastRP_Embedding_Extended'
})
YIELD nodePropertiesWritten, mutateMillis, nodeCount, createMillis, computeMillis;

//Model Training and Evaluation, should be fastRP_Embedding_Extended here.  275020 ms.
//   featureProperties: ['fastRP_Embedding'], 
CALL gds.alpha.ml.linkPrediction.train('linkpred', {
  trainRelationshipType: 'CO_AUTHOR_TRAINGRAPH',
  testRelationshipType: 'CO_AUTHOR_TESTGRAPH',
  modelName: 'model-only-embedding',
  featureProperties: ['fastRP_Embedding_Extended'],
  validationFolds: 5,
  classRatio: 1.0,
  randomSeed: 2,
  params: [
    {penalty: 0.25, maxIterations: 1000},
    {penalty: 0.5, maxIterations: 1000},
    {penalty: 1.0, maxIterations: 1000},
    {penalty: 0.0, maxIterations: 1000}
  ]
})
YIELD trainMillis, modelInfo
RETURN trainMillis,
       modelInfo.bestParameters AS winningModel,
       modelInfo.metrics.AUCPR.outerTrain AS trainGraphScore,
       modelInfo.metrics.AUCPR.test AS testGraphScore;

// One model for community edition in memory  
call gds.beta.model.drop('model-only-embedding')  

CALL gds.alpha.ml.linkPrediction.train('linkpred', {
  trainRelationshipType: 'CO_AUTHOR_TRAINGRAPH',
  testRelationshipType: 'CO_AUTHOR_TESTGRAPH',
  modelName: 'model-only-embedding-hadamard',
  featureProperties: ['fastRP_Embedding_Extended'],
  validationFolds: 5,
  classRatio: 1.0,
  randomSeed: 2,
  params: [
    {penalty: 0.25, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'},
    {penalty: 0.5, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'},
    {penalty: 1.0, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'},
    {penalty: 0.0, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'}
  ]
})
YIELD modelInfo
RETURN modelInfo.bestParameters AS winningModel,
       modelInfo.metrics.AUCPR.outerTrain AS trainGraphScore,
       modelInfo.metrics.AUCPR.test AS testGraphScore;

CALL gds.beta.model.list()
YIELD modelInfo
CALL gds.beta.model.drop(modelInfo.modelName)
YIELD modelInfo AS info
RETURN info;

UNWIND [
  ["fastRP_Embedding_Extended"],
  ["fastRP_Embedding", "pagerank", "triangles"],
  ["fastRP_Embedding", "pagerank"],
  ["fastRP_Embedding", "triangles"],
  ["fastRP_Embedding"]
] AS featureProperties
CALL gds.alpha.ml.linkPrediction.train('linkpred', {
  trainRelationshipType: 'CO_AUTHOR_TRAINGRAPH',
  testRelationshipType: 'CO_AUTHOR_TESTGRAPH',
  modelName: 'model-' + apoc.text.join(featureProperties, "-"),
  featureProperties: featureProperties,
  validationFolds: 5,
  classRatio: 1.0,
  randomSeed: 2,
  params: [
    {penalty: 0.25, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'},
    {penalty: 0.5, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'},
    {penalty: 1.0, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'},
    {penalty: 0.0, maxIterations: 1000, linkFeatureCombiner: 'HADAMARD'}
  ]
})
YIELD modelInfo
RETURN modelInfo;

CALL gds.beta.model.list()
YIELD modelInfo
RETURN modelInfo.modelName AS modelName,
       modelInfo.bestParameters AS winningModel,
       modelInfo.metrics.AUCPR.outerTrain AS trainGraphScore,
       modelInfo.metrics.AUCPR.test AS testGraphScore
ORDER BY testGraphScore DESC;
