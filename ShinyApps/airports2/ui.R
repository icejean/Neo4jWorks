# 浏览器端UI函数，画机场航线网络图。
fluidPage(
  # Javascript 处理父窗口传入的参数等。
  tags$head(tags$script("
                // 记录父窗口，初始为空。
                parent = null;
                // 处理接收到的消息。
                window.addEventListener('message', function(e) {
                        //alert(e.data);
                        try{
                            //记录父窗口以备回发信息
                            parent = e.source;
                            //向服务器发送input变量更新消息
                            //Shiny.setInputValue('airport', e.data, {priority:'event'});
                            Shiny.setInputValue('airport', e.data);
                        } catch (error){
                              alert(error);
                            }
                        },false);

                // 点击时传出参数    
                $(document).on('click', '.btn-success', function (evt) {
                      evt.preventDefault(); 
                      var selected = document.getElementById('nodes_selected');
                      if (selected ==null){
                         alert('No node is selected!');
                      }else{
                        if (parent == null){
                          alert(selected.innerHTML);
                        } else {
                          try{
                            parent.postMessage(selected.innerHTML, '*');
                          } catch(error){
                            alert(error);
                          }
                        }
                      }
                });  
                
              ")),
  # Application title
  titlePanel("机场航线示例"),
  sidebarLayout(
    # Sidebar with a selectioninput and a numericInput
    sidebarPanel(
      selectInput(
        'airport',
        '国内机场',
        airports,
        selected = 'Zhuhai Airport'
      ),
      #numericInput("hops", "最多转机次数", value = 0, min = 0, max = 2),
      sliderInput("hops",
                  "最多转机次数：",
                  min = 0,  max = 2, value = 0),      
      checkboxInput("ifRecord","记录点击的节点", value = FALSE),
      textInput("node_selected","选中的节点",""),
      actionButton("sendout", "传出选中节点", class = "btn-success"),
      actionButton("clearNodes", "清除选中节点", class = "btn-cleear")
    ),
    # Show the network
    mainPanel(
      # 画航线网络图
      visNetworkOutput("plot"),
      hr(),
      tags$div(
        "已选择的节点"
      ),
      hr(),
      textOutput("nodes_selected"),
      # 禁止自己修改 node_selected textInput
      tags$script(HTML(
        'var node_selected = document.getElementById("node_selected");',
        "node_selected.disabled = true;"
      )) 
    )
  )
)

