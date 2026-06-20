import pandas as pd
from neo4j import GraphDatabase, basic_auth
from neo4j import neo4jkeys

# bolt： 无SSL
# bolt+s :SSL并检查证书链
# bolt+ssc: SSL但不检查证书链，自签证书专用
# 同样适用于neo4j协议, neo4j+s，neo4j+ssc
# https://neo4j.com/docs/python-manual/current/client-applications/
# # GDS升级到2.5.5，算法调用有变化，已更正, Neo4j 升级到5.10.0
# 只返回最短路径
def getAirLines(source, length):
  driver = GraphDatabase.driver("bolt+ssc://localhost:7687", auth=basic_auth(neo4jkeys.user, neo4jkeys.password))
  with driver.session(database="neo4j") as session:
      graph = session.execute_read(path_to_airports, source,length)
  driver.close()
  return graph    


# GDS升级到2.5.5，算法调用有变化，已更正
def path_to_airports(tx, source, length):
    # 先建立图的投影
    cypher = '''
CALL gds.graph.exists('airportsNetwork_CN')
  YIELD graphName, exists
WHERE NOT exists
CALL gds.graph.project.cypher(
    'airportsNetwork_CN',
    'MATCH (n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
                RETURN id(n) AS id',
    'MATCH (startNode:Airport)-[r:HAS_ROUTE]->(targetNode:Airport),
                        (startNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}),
                        (targetNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})                                                                  RETURN id(startNode) AS source, id(targetNode) AS target, r.distance AS distance'
) YIELD
  graphName AS graph, nodeQuery, nodeCount AS nodes, relationshipQuery, relationshipCount AS rels     
RETURN graphName, nodes, rels;    
    ''' 
    result = tx.run(cypher).single() 
    # 再调用图算法
    cypher = '''
CALL {
    MATCH (start:Airport{descr:$name})
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
WHERE length(path)<=$len  
WITH nodes(path) AS pnodes                                         
UNWIND range(0, size(pnodes)-1) AS index
WITH pnodes[index] AS current, pnodes[index+1] AS next
MATCH (current)-[r:HAS_ROUTE]->(next)
RETURN current.descr AS source, next.descr as target, r.distance AS distance;  
    '''
    start = []; target=[]; distance=[]
    for record in tx.run(cypher, name=source, len=length):
        start.append(record["source"])
        target.append(record["target"])
        distance.append(record["distance"])
    # 从 list建立 pandas data frame
    data = pd.DataFrame({"source":start,"target":target,"distance":distance})
    
    return data


# 返回完全子网
def getAirLines2(source, length):
  driver = GraphDatabase.driver("bolt+ssc://localhost:7687", auth=basic_auth(neo4jkeys.user, neo4jkeys.password))
  with driver.session(database="neo4j") as session:
      graph = session.execute_read(airports_network, source,length)
  driver.close()
  return graph    


# Neo4j 不允许将可变长路径中的最大长度作为参数，这里用变通的办法绕过，把长度参数转换为字符串，先拼接成固定的Cypher语句。
# 另一个参数source则通过占位符在执行时动态替换
# 参阅：
# https://stackoverflow.com/questions/42386273/cypher-query-to-give-path-length-as-a-parameter-for-variable-length-relationship
# https://stackoverflow.com/questions/42668225/neo4j-pass-parameter-to-variable-length-relationship
# https://blog.csdn.net/xckkcxxck/article/details/79691594
def airports_network(tx, source,length):
    # 先建立图的投影
    cypher = '''
CALL gds.graph.exists('airportsNetwork_CN')
  YIELD graphName, exists
WHERE NOT exists
CALL gds.graph.project.cypher(
    'airportsNetwork_CN',
    'MATCH (n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
                RETURN id(n) AS id',
    'MATCH (startNode:Airport)-[r:HAS_ROUTE]->(targetNode:Airport),
                        (startNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}),
                        (targetNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})                                                                  RETURN id(startNode) AS source, id(targetNode) AS target, r.distance AS distance'
) YIELD
  graphName AS graph, nodeQuery, nodeCount AS nodes, relationshipQuery, relationshipCount AS rels     
RETURN graphName, nodes, rels;    
    ''' 
    result = tx.run(cypher).single() 
    # 再调用图算法
    cypher = (\
'''
MATCH (target:Airport)-[:IN_COUNTRY]->(c:Country{code:'CN'})
WITH target
MATCH path = (start:Airport{descr:$name})-[r:HAS_ROUTE*1..'''+str(int(length))+"]->(target)"+\
'''
WITH *, relationships(path) as flights
UNWIND flights AS flight
WITH DISTINCT flight                   
MATCH (n:Airport)-[flight]->(m:Airport)
RETURN n.descr AS source, m.descr as target, flight.distance AS distance;      
'''
    )
    # print(cypher)
    start = []; target=[]; distance=[]
    for record in tx.run(cypher, name=source):
        start.append(record["source"])
        target.append(record["target"])
        distance.append(record["distance"])
    # 从 list建立 pandas data frame
    data = pd.DataFrame({"source":start,"target":target,"distance":distance})
    return data


def getRings(source, length, amplitude, threshold):
  driver = GraphDatabase.driver("bolt+ssc://localhost:7687", auth=basic_auth(neo4jkeys.user, neo4jkeys.password))
  with driver.session(database="neo4j") as session:
      graph = session.execute_read(airports_ring, source, length, amplitude, threshold)
  driver.close()
  return graph    


def airports_ring(tx, source, length, amplitude, threshold):
    # 先建立图的投影
    cypher = '''
CALL gds.graph.exists('airportsNetwork_CN')
  YIELD graphName, exists
WHERE NOT exists
CALL gds.graph.project.cypher(
    'airportsNetwork_CN',
    'MATCH (n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
                RETURN id(n) AS id',
    'MATCH (startNode:Airport)-[r:HAS_ROUTE]->(targetNode:Airport),
                        (startNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}),
                        (targetNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})                                                                  RETURN id(startNode) AS source, id(targetNode) AS target, r.distance AS distance'
) YIELD
  graphName AS graph, nodeQuery, nodeCount AS nodes, relationshipQuery, relationshipCount AS rels     
RETURN graphName, nodes, rels;    
    ''' 
    result = tx.run(cypher).single() 
    # 再调用图算法
    cypher = (\
'''
MATCH (china:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})
WITH COLLECT(china.id) AS targets
MATCH path = (source:Airport{descr:$name})-[r:HAS_ROUTE*2..'''+str(int(length))+"]->(target)"+\
'''
WHERE target.descr = source.descr
      AND ALL( node IN nodes(path) where node.id IN targets)
WITH path, [r in relationships(path)|r.distance] AS distances, $amplitude AS amplitude, $threshold AS threshold
//WITH path, apoc.coll.avg(distances) AS avgDist, apoc.coll.min(distances) as minDist, apoc.coll.max(distances) as maxDist
//WHERE minDist/avgDist >= (1-amplitude) AND maxDist/avgDist <= (1+amplitude) AND avgDist >= threshold
WITH path, apoc.coll.median(distances) AS medianDist, apoc.coll.min(distances) as minDist, apoc.coll.max(distances) as maxDist
WHERE minDist/medianDist >= (1-amplitude) AND maxDist/medianDist <= (1+amplitude) AND medianDist >= threshold
WITH path, relationships(path) as flights
UNWIND flights AS flight
WITH DISTINCT flight
MATCH (n:Airport)-[flight]->(m:Airport)
RETURN n.descr AS source, m.descr as target, flight.distance AS distance;      
'''
    )
    print(cypher)
    start = []; target=[]; distance=[]
    for record in tx.run(cypher, name=source, amplitude=amplitude, threshold=threshold ):
        start.append(record["source"])
        target.append(record["target"])
        distance.append(record["distance"])
    # 从 list建立 pandas data frame
    data = pd.DataFrame({"source":start,"target":target,"distance":distance})
    return data


# 返回国内机场列表
def getAirports(country):
  driver = GraphDatabase.driver("bolt+ssc://localhost:7687", auth=basic_auth(neo4jkeys.user, neo4jkeys.password))
  with driver.session(database="neo4j") as session:
      # graph = session.read_transaction(countryAirports, country) # Neo4j 5.16.0
      graph = session.execute_read(countryAirports, country)
  driver.close()
  return graph    


def countryAirports(tx, country):
    cypher="match (n:Airport)-[:IN_COUNTRY]->(c:Country{code:$code}), \
                  (n:Airport)-[:HAS_ROUTE]->(target) return distinct n.descr as name"
    airports = []
    for record in tx.run(cypher, code=country):
        airports.append(record["name"])
    # 从 list建立 pandas data frame
    data = pd.DataFrame({"airport":airports})
    return data
  
  
def CypherQuery(cql):
  driver = GraphDatabase.driver("bolt+ssc://localhost:7687", auth=basic_auth(neo4jkeys.user, neo4jkeys.password))
  with driver.session(database="neo4j") as session:
      graph = session.execute_read(execute_cypher, cql)
  driver.close()
  return graph    


def execute_cypher(tx, cql):
    # 先建立图的投影
    cypher = '''
CALL gds.graph.exists('airportsNetwork_CN')
  YIELD graphName, exists
WHERE NOT exists
CALL gds.graph.project.cypher(
    'airportsNetwork_CN',
    'MATCH (n:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}) 
                RETURN id(n) AS id',
    'MATCH (startNode:Airport)-[r:HAS_ROUTE]->(targetNode:Airport),
                        (startNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"}),
                        (targetNode:Airport)-[:IN_COUNTRY]->(c:Country{code:"CN"})                                                                  RETURN id(startNode) AS source, id(targetNode) AS target, r.distance AS distance'
) YIELD
  graphName AS graph, nodeQuery, nodeCount AS nodes, relationshipQuery, relationshipCount AS rels     
RETURN graphName, nodes, rels;    
    ''' 
    result = tx.run(cypher).single() 
    # 再调用图算法
    # print(cypher)
    start = []; target=[]; distance=[]
    for record in tx.run(cql):
        start.append(record["source"])
        target.append(record["target"])
        distance.append(record["distance"])
    # 从 list建立 pandas data frame
    data = pd.DataFrame({"source":start,"target":target,"distance":distance})
    return data

def project(cql):
  driver = GraphDatabase.driver("bolt+ssc://localhost:7687", auth=basic_auth(neo4jkeys.user, neo4jkeys.password))
  with driver.session(database="neo4j") as session:
      graph = session.execute_read(execute_projection, cql)
  driver.close()
  return graph    

def execute_projection(tx, cql):
    # 先删除旧的投影
    cydrop ='''
CALL gds.graph.exists('airportsNetwork_CN')
  YIELD graphName, exists
WHERE exists
CALL gds.graph.drop(graphName)
 YIELD graphName as graphDeleted
 RETURN graphDeleted    
    '''
    try:
      result = tx.run(cydrop).single()
    except:
      pass
    # 再建新的投影
    result = tx.run(cql).single() 
    return result

  
  
# source = "Zhuhai Airport"
# graph = getAirLines(source,2)
# graph2 = getAirLines2(source,2)
# graph3 = getRings(source,2,0.2,500)

airports = getAirports("CN")
cypher = '''
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
'''

projection = '''
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
RETURN graph, nodes, rels;    
'''

results = project(projection)
