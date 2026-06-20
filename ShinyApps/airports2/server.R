# 服务端函数，根据浏览器选定的机场选出其给定步数内航线可达的机场。
function(input, output, session) {
  # 定义reactive变量，监视输入的变化
  airport<- reactive({
    input$airport
  })
  
  hops<- reactive({
    as.integer(input$hops)+1
  })
  
  node_selected<-reactive({
    input$node_selected
  })
  
  # 监视输入变量变化事件，这是为嵌入宿主网页更新浏览器端输入变量准备的。
  observeEvent(airport(),{
    # 这一句执行了,证明触发了
    print(paste("Airport event triggered: ",airport()))
    # 注意这里用updateTextInput更新文本到浏览器端，如果用updateSelectInput()会报错，可能要求的是下标。
    updateTextInput(session, "airport", value = airport())
  })
  
  observeEvent(hops(),{
    # 这一句执行了,证明触发了
    print(paste("Hops event triggered: ",hops()))
    #updateNumericInput(session, "hops", value = hops()-1)
    updateSliderInput(session, "hops", value = hops()-1)
  })  
  
  observeEvent(node_selected(),{
    # 这一句执行了,证明触发了
    print(paste("Node selected event triggered: ",node_selected()))
    updateTextInput(session, "node_selected", value = node_selected())
  })    

  # 用Chrome devtools->elements展开当前的DOM对象，可以看到正确的 DOM id是 nodeSelectplot
  # observeEvent(input$nodeSelectplot,{
  #   # 这一句执行了,证明触发了
  #   print(paste("Node selected event triggered: ",input$nodeSelectplot))
  # })    
  
  # 清除选中节点
  observeEvent(input$clearNodes,{
    session$userData$nodes_selected <- ""
    updateTextInput(session, "node_selected", value = "")
  })
  
  # 更新网络图
  output$plot <- renderVisNetwork({
    # 调Python函数得到指定机场指定跳数以内的通达航线图
    graph<- getAirLines(airport(),hops())
    # 合并多重边，存在多条路径都经过同一条边的情况，统计多重边的数量作为合并后边的权重。
    graph2<-sqldf("select source,target,distance, count(*) as paths 
                from graph group by source,target,distance 
                order by source,target")
    # 建立 igraph图
    g <- graph.data.frame(graph2, directed = TRUE)
    # 节点标签
    V(g)$label<-V(g)$name
    # 边宽度
    E(g)$width<-E(g)$paths
    # 边标签
    E(g)$label<-as.character(E(g)$distance)
    
    # 输出转换成vsNetwork包要求的vertices & edges dataframe
    verts<- as_data_frame(g, what="vertices")
    # 必须有id列
    names(verts)<-c("id", "label")
    edges<- as_data_frame(g, what="edges")
    # 生成网络可视化图
    title <- paste(airport(),"转机 ",hops()-1," 次以内航线图",sep="")
    vg<-visNetwork(nodes=verts, edges=edges, main=title) %>% 
        visEdges(arrows = 'to') %>% 
        visEvents(selectNode = 
        "function(properties) {
                var ifRecord = document.getElementById('ifRecord');
                //alert(ifRecord.checked);
                if(ifRecord.checked){
                  var data = this.body.data.nodes.get(properties.nodes[0]).id;
                  //alert('selected nodes ' + data);
                  Shiny.setInputValue('node_selected', data, {priority:'event'});
                }
        }"
        )
    # nodesIdSelection选项还没有找到正确的 input DOM id,文档所说的 $plot_selected不对。
    # 参阅： https://datastorm-open.github.io/visNetwork/shiny.html
    # 用上面的visEvents(selectNode = function())代替。
    # 参阅： https://datastorm-open.github.io/visNetwork/more.html
    # 用Chrome devtools->elements展开当前的DOM对象，可以看到正确的 DOM id是 noeSelectplot，
    # 其中plot是上面输出的本网络图的id output$plot，
    # 这里还是用visEvents()来处理，先检查记录点击节点的开关是否打开再发送点击事件通知服务器端。
    # visOptions(vg, nodesIdSelection = TRUE,  manipulation = TRUE)
    visOptions(vg,  manipulation = TRUE)
  })
  # 显示选中的节点
  output$nodes_selected <- renderText({
    session$userData$nodes_selected<-paste(session$userData$nodes_selected,node_selected(),sep="!")
  })
}

