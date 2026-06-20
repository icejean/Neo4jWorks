# 服务端函数，根据浏览器选定的机场选出其给定步数内航线可达的机场。
function(input, output, session) {
  # 定义reactive变量，监视输入的变化
  # 选定的机场
  airport<- reactive({
    input$airport
  })
  # Cypher语句
  cypher<- reactive({
    input$cypher
  })
  # 投影语句
  graph_projection<- reactive({
    input$projection
  })
  # 选中的结点
  nodes_selected<-reactive({
    input$nodes_selected
  })
  
  # 监视执行查询按钮点击事件。
  # Cypher语句Tab------------------------------------------------------------------------------
  observeEvent(input$excuteCypher, {
    req(cypher(),graph_projection())
    # 这一句执行了,证明触发了
    print("Excuting Cypher query...")
    # Show notification while querying.
    id <- showNotification("正在加载网络数据...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    try({
      t1<-proc.time()
      # 调Python函数执行Cypher语句得到子网
      graph<- CypherQuery(cypher())
      t2<-proc.time()
      timeUsed <- t2-t1
      
      # 合并多重边，存在多条路径都经过同一条边的情况，统计多重边的数量作为合并后边的权重。
      graph2<-sqldf("select source,target,distance, count(*) as paths 
                from graph group by source,target,distance 
                order by source,target")
      # 建立 igraph图
      g <- graph.data.frame(graph2, directed = TRUE)
      # 节点标签
      V(g)$label<-V(g)$name
      # 节点的航班数，最短路径子网统计出度和入度，因为末端的结点只有入度。这是为了演示设置结点的大小。
      # 对于完全子网，航线比较多，只统计入度
      V(g)$size <- degree(g, mode="out")
      # 最短路径子网边的宽度
      E(g)$width<-E(g)$distance/200
      # 边标签
      E(g)$label<-as.character(E(g)$distance)
      
      # 测试通过颜色属性设置结点的颜色，这样可以通过igraph先设定结点与边的颜色，再传给3D Forced Directed Graph
      # 这4句只是测试用途，可以不用管
      V(g)$color<-"#00BFFF"
      V(g)$color[1]<-"red"
      E(g)$color<-"green"
      E(g)$color[1]<-"red"
      
      # 转换为 3D Force-Directed Graph 要求的json网络格式。
      # 结点列表
      verts<- as_data_frame(g, what="vertices")
      # 必须有id列
      names(verts)<-c("id", "label", "size","color")
      # 边列表
      edges<- as_data_frame(g, what="edges")
      names(edges)<-c("source", "target","distance","paths","width","label","color")
      jsonVerts<- toJSON(verts)
      jsonEdges<- toJSON(edges)
      # 合并结点与边的json数据集
      jsonGraph<- paste('{
        "nodes": ',jsonVerts,',
        "links": ',jsonEdges,'}')
      
      # 图数据存储在session对象中
      session$userData$jsonGraph<- jsonGraph
      session$userData$verts<- verts
      #暂时这样，第一个结点设置为源结点。
      session$userData$sourceNode<-verts[1,2]
      print("Graph data updated.")
      
      output$cypher_reults<-renderText(paste("Cypher执行结果: 结点 ",length(verts[,1]),"，边 ", length(edges[,1]),"。"))
      output$verts_list<- renderDataTable(verts, selection = 'single',
                                   options = list(
                                     pageLength = 10,
                                     language = list(url = 'Chinese.json')   
                                   )
      )
      output$edges_list<- renderDataTable(edges,
                                   options = list(
                                     pageLength = 10,
                                     language = list(url = 'Chinese.json')   
                                   )
      )
    })
  })
  
  # 可视化分析Tab---------------------------------------------------------------------------
  # 浏览器端结点的javascript中.onNodeClick((node, event)事件处理，
  # 发送消息函数Shiny.setInputValue('nodes_selected', nodeList)会触发这个事件处理函数。
  observeEvent(nodes_selected(),{
    # 这一句执行了,证明触发了
    print(paste("Nodes selected event triggered: ",nodes_selected()))
    # 在session中记录选中的结点，记录APP的状态
    session$userData$nodes_selected<- nodes_selected()
    # 更新浏览器端显示的输入变量nodes_selected
    updateTextAreaInput(session, "nodes_selected", value = nodes_selected())
  })    
  
  # 清除选中节点，浏览器端点击'清除选中结点'按钮会触发这个事件处理函数。
  observeEvent(input$clearNodes,{
    print("Clear nodes selected event triggered.")
    # 更新session中记录的用户数据
    session$userData$nodes_selected <- ""
    # 更新浏览器端显示的输入变量nodes_selected
    updateTextAreaInput(session, "nodes_selected", value = "")
    # 发送一个清理指令给浏览器端注册的javascript函数，重置图中选中结点的颜色并更新APP的状态。
    session$sendCustomMessage("clearSelectedNodes", airport())    
  })
  
  # 切换到3D可视化页面时重新发送图数据，以便重新渲染3D图，否则3D图无法旋转，这是一个已知的issue:
  # https://github.com/vasturiano/3d-force-graph/issues/627
  # rotate not available when the 3D graph is inside a html tab/div container
  observeEvent(input$tabs, {
    if (input$tabs == "可视化分析") {
      # Show notification while querying.
      id <- showNotification("正在渲染3D视图...", duration = NULL, closeButton = FALSE)
      on.exit(removeNotification(id), add = TRUE)
      # 图数据存储在session对象中
      jsonGraph<- session$userData$jsonGraph
      # 发送给浏览器，更新网络图
      session$sendCustomMessage("updateGraphData", jsonGraph)
      print("Graph data sent.")
      sourceNode = session$userData$sourceNode
      print(paste("Source node: ",sourceNode))
      # 更新浏览器端textInput的状态，设置源结点。稍后修改为从子图中选取。
      updateTextInput(session, "airport", value = sourceNode)
      # 设置初始视野，通知浏览器端聚焦源结点并着色，以便分析。
      session$sendCustomMessage("setSourceNode", sourceNode)
    }
  })
  
  #结点列表Tab--------------------------------------------------------------------------------------
  # 返回并显示选中行的行名，行名是全局的，用于定位对应的行，更新浏览器端显示。
  observe({
    verts<- session$userData$verts
    label<- verts[as.integer(input$verts_list_rows_selected),2]
    output$row_selected<-renderText(label)
    print(label)
  })
  
  observeEvent(input$setAsSourceNode,{
    # Show notification while querying.
    id <- showNotification("正在设置源结点...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    
    verts<- session$userData$verts    
    sourceNode<-verts[as.integer(input$verts_list_rows_selected),2]
    session$userData$sourceNode<-sourceNode
    # 更新session中记录的用户数据
    session$userData$nodes_selected <- ""
    # 更新浏览器端显示的输入变量nodes_selected
    updateTextAreaInput(session, "nodes_selected", value = "")
    # 发送一个清理指令给浏览器端注册的javascript函数，重置图中选中结点的颜色并更新APP的状态。
    session$sendCustomMessage("clearSelectedNodes", sourceNode)    
    print(paste("Set source node to: ",sourceNode))
  }) 
  
  #投影语句Tab--------------------------------------------------------------------------------------
  observeEvent(input$excuteProjecttion, {
    req(graph_projection())
    # Show notification while querying.
    id <- showNotification("正在进行网络投影...", duration = NULL, closeButton = FALSE)
    on.exit(removeNotification(id), add = TRUE)
    print("Setting projection")
    t1<-proc.time()
    # 调Python函数执行Cypher语句得到子网
    results<- project(graph_projection())
    t2<-proc.time()
    timeUsed <- t2-t1
    print("Projection results")
    print(results)
    output$projection_reults<-renderText(paste("投影结果: 子图 ",results['graph'],
                                               "，结点 ",results['nodes'],"，边 ", results['rels'],"。"))
  })    
  
}

