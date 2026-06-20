# 服务端函数，根据浏览器选定的机场选出其给定步数内航线可达的机场。
function(input, output, session) {
  # 定义reactive变量，监视输入的变化
  # 选定的机场
  airport<- reactive({
    input$airport
  })
  # 指定的跳数
  hops<- reactive({
    
    as.integer(input$hops)
  })
  # 指定的振幅内
  amplitude<- reactive({
    as.numeric(input$amplitude)
  })
  # 指定的阀值内
  threshold<- reactive({
    as.integer(input$threshold)
  })  
  # 选中的结点
  nodes_selected<-reactive({
    input$nodes_selected
  })
  # 监视输入变量airport与hops的变化事件。
  observe({
    # 这一句执行了,证明触发了
    print(paste("Observe triggered: ",paste(airport(),hops())))
    
    try({
      t1<-proc.time()
      # 调Python函数得到指定机场指定跳数以内的航线环路图
      graph<- getRings(airport(),hops(), amplitude(), threshold())
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

      # 发送给浏览器，更新网络图
      session$sendCustomMessage("updateGraphData", jsonGraph)
      # 更新浏览器端selectInput的状态
      # 注意这里用updateTextInput更新文本到浏览器端，如果用updateSelectInput()会报错，可能要求的是下标。
      updateTextInput(session, "airport", value = airport())
      # 设置初始视野，通知浏览器端聚焦源结点并着色，以便分析。
      session$sendCustomMessage("setSourceNode", airport())
      # 这个过程需要点时间，告知客户端更新APP状态。
      updateTextInput(session, "appstatus", value = paste("网络数据已加载: ",round(timeUsed[3],1),"秒",sep=""))
    })
  })
  
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
  
}

