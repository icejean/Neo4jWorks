# 浏览器端UI函数，画机场航线网络图。
fluidPage(
  # Javascript 处理父窗口传入的参数等。
  tags$head(
    
    tags$style(HTML("
        .app-title {
          position: absolute;
          top: 5px;
          right: 20px;
          font-size: 24px;
          font-weight: bold;
        }
      ")),
    tags$script(HTML("
                // 记录父窗口，初始为空。
                parent = null;
                // 处理接收到的消息，没有传入的参数。
                window.addEventListener('message', function(e) {
                        //alert(e.data);
                        try{
                            //记录父窗口以备回发信息
                            parent = e.source;
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
                          alert(selected.value);
                        } else {
                          try{
                            parent.postMessage(selected.value, '*');
                          } catch(error){
                            alert(error);
                          }
                        }
                      }
                });  
                
                // 触发了shiny:inputchanged事件，有些是纯浏览器端事件，从浏览器端更新状态提示。
                $(document).on('shiny:inputchanged', function(event) {
                    var appstatus = document.getElementById('appstatus');
                    if (event.name === 'sendout') {
                        appstatus.value = '选中结点已传出';
                    }
                    if (event.name === 'ifMultiEdge') {
                        // 不向服务器端传送信息，边曲线是纯粹的可视化效果
                        event.preventDefault(); 
                        try{
                            var ifMultiEdge = document.getElementById('ifMultiEdge');
                            // .linkVisibility(false).linkVisibility(true) 确保刷新视图
                            if (ifMultiEdge.checked){
                              mygraph.linkCurvature(0.25)
                                     .linkVisibility(false)
                                     .linkVisibility(true);
                              appstatus.value = '已展开重叠边的直线';
                            }else{
                              mygraph.linkCurvature(0)
                                     .linkVisibility(false)
                                     .linkVisibility(true);
                              appstatus.value = '已叠加多重边为直线';
                            }
                        }catch(error){
                            alert(error);
                        }
                    }
                });
                
              "))
  ),
  
  div(class = "app-title", "通用网络分析Shiny APP示例"),
  
  tabsetPanel(id = "tabs",
              tabPanel("Cypher语句",
                       mainPanel(
                         textAreaInput("cypher","Cypher语句", width='1000px', rows =24, resize="vertical", value =cypher),
                         actionButton("excuteCypher", "执行查询", class = "btn-query"),
                         tags$h6(" "),
                         textOutput("cypher_reults")
                       )),  
              tabPanel("结点列表",
                       mainPanel(
                         dataTableOutput("verts_list"),
                         tags$h4("选中结点 "),               
                         textOutput("row_selected"),
                         actionButton("setAsSourceNode", "设为源结点", class = "btn-source")              
                       )),  
              tabPanel("边列表",
                       mainPanel(
                         dataTableOutput("edges_list"),
                       )),  
              
              tabPanel("可视化分析",    
                       sidebarLayout(
                         sidebarPanel(
                           # Application title
                           tags$h3("机场航线网络"),
                           textInput('airport','国内机场',value=""),
                           checkboxInput("ifRecord","记录点击的结点", value = FALSE),
                           # 手机没有键盘，这个开关是为了方便手机使用
                           checkboxInput("ifMultiSelect","连续选取结点", value = TRUE),
                           checkboxInput("ifMultiEdge","用曲线展开多重边", value = FALSE),
                           actionButton("sendout", "传出选中结点", class = "btn-success"),
                           tags$h6(" "),
                           actionButton("clearNodes", "清除选中结点", class = "btn-cleear"),
                           tags$h6(" "),
                           textInput("appstatus","APP状态", value =""),
                           textAreaInput("nodes_selected","选中的结点", rows =6, resize="vertical", value =""),
                           # 插入javascript，禁止自己修改 nodes_selected textAreaInput, appstatus textInput
                           tags$script(HTML("
        var nodes_selected = document.getElementById('nodes_selected');
        nodes_selected.disabled = true;
        var appstatus = document.getElementById('appstatus');
        appstatus.disabled = true;
      ")),
                           
                           # 1/6
                           width = 2
                         ),
                         # Show the network
                         mainPanel(
                           # 画航线网络图
                           # 定义图显示的区域, 在该区域中加载图
                           tags$div(id="3d-graph"),
                           
                           # Style sheet of node label
                           tags$head(
                             tags$style("
          .node-label {
              font-size: 12px;
              padding: 1px 4px;
              border-radius: 4px;
              color: LightGoldenRodYellow;
              background-color: none;  // rgba(0,0,0,0.5)
              user-select: none;   
            }
      ")),
                           # 定义后面消息处理函数要使用的全局变量
                           HTML("
      <script>
        //定义图的全局变量
        //保存对Graph对象的全局引用，取消结点选择时要处理图的结点与边
        let mygraph = null;
        //选中的结点集
        let selectedNodes = new Set();
        //选中的结点集之间的边
        let highlightLinks = new Set();

        //选中结点与未选中结点的颜色
        // 参见下面链接中的颜色表。
        // https://www.w3schools.com/tags/ref_colornames.asp
        // 最好写成#十六进制，有些按名称引用的可能不认识。边的颜色会被稀释淡化，所以不少颜色之间可能看不出区别。
        let colorNodeSelected = 'GoldenRod';
        let colorNode         = 'LightSeaGreen';
        // 选中边与未选中边的颜色
        let colorEdgeSelected = 'gold'; 
        let colorEdge         = '#20B2AA'; // #20B2AA, LightSeaGreen， rgb(32, 178, 170)。
           
        // 更新加载状态的引用
        let APPStatus = document.getElementById('appstatus');
        
        // 初始化为一个空图
        let gData = {
            nodes: [],
            links: []
        };
           
      </script>
           "),
                           
                           # Scripts for Vasturiano 3D Force-Directed Graph
                           # load 3d-force-graph.js, three.js
                           # tags$script(src = "3d-force-graph.js"), 
                           # Will cause an error: Cannot use import statement outside a module
                           # It's O.K. this way, but need to connect to unpkg.com
                           tags$script(src="//cdn.jsdelivr.net/npm/three"),
                           tags$script(src="//cdn.jsdelivr.net/npm/3d-force-graph"),
                           
                           # 定义后面消息处理函数updateGraphData()要导入的javascript库，ECMAScript modules
                           HTML('
            <script type="importmap">{ "imports": {
                "three": "//cdn.jsdelivr.net/npm/three/build/three.module.js",
                "three/addons/": "//cdn.jsdelivr.net/npm/three/examples/jsm/",
                "three-spritetext": "//cdn.jsdelivr.net/npm/three-spritetext/dist/three-spritetext.mjs"
            }}</script>
           '),
                           # 注册一个javascript消息处理函数，接收服务器发来的json图数据，更新图
                           # 用HTML(), 否则javascript lambda表达式的=>箭头会被替换成&转义符，导致javascript执行出错。
                           # 消息类型是updateGraphData，格式是json。
                           HTML("
      <script type='module'>
        import { CSS2DRenderer, CSS2DObject } from '//cdn.jsdelivr.net/npm/three/examples/jsm/renderers/CSS2DRenderer.js';
        import SpriteText from 'three-spritetext';
        
        //接收服务器传来的json图数据，转换为图对象
        Shiny.addCustomMessageHandler('updateGraphData', function(data) {
          //装入图数据json对象
          try {
            gData = JSON.parse(data);
          } catch(error){
            //alert(error);
            return;
          }
          
          // 为Vasturiano 3D Force-Directed Graph的javascript表示补充邻接表结构，以便javascript中执行图算法。
          // 初始化邻接表，为结点增加neighbors列表与links列表
          gData.nodes.forEach(node => {
                node.neighbors=[];
                node.links=[];
          });
          // 邻接是双向的，这里初始化为无向图邻接，也可以按需要初始化为有向图邻接。
          gData.links.forEach(link => {
              // 按属性值查找出源与目标结点
              var sourceNode = gData.nodes.find(obj => {return obj.id === link.source});
              var targetNode = gData.nodes.find(obj => {return obj.id === link.target});
              sourceNode.neighbors.push(link.target);
              targetNode.neighbors.push(link.source);
              sourceNode.links.push(link);
              targetNode.links.push(link);
          });
          
          APPStatus.value = '正在加载网络数据...';
          
          //加载图，可视化显示
          const Graph = ForceGraph3D({
              // 用于为结点加上标签
              extraRenderers: [new CSS2DRenderer()]
            })  
            // 获得显示的区域，上面tags$div(id='3d-graph')定义的对象
            (document.getElementById('3d-graph'))
            // 加载数据
            .graphData(gData )
            // 加载测试数据
            //.jsonUrl('https://raw.githubusercontent.com/vasturiano/3d-force-graph/master/example/datasets/miserables.json')
            // 定义结点标签，鼠标移动到上面时会显示
            .nodeLabel('id')
            // 设定结点的大小
            .nodeVal(node => node.size)
            // 按组显示颜色
            //.nodeAutoColorBy('group')
            // 选中的结点以不同的颜色标记
            .nodeColor(node => selectedNodes.has(node) ? colorNodeSelected : colorNode)
            // 也可以通过指定结点的颜色属性名称来指定结点的颜色，这样可以先在igraph中处理
            //.nodeColor('color')
            // 为结点加上标签，使用结点扩展
            .nodeThreeObject(node => {
                const nodeEl = document.createElement('div');
                nodeEl.textContent = node.id;
                //nodeEl.style.color = node.color;
                nodeEl.className = 'node-label';
                return new CSS2DObject(nodeEl);
            }) 
            .nodeThreeObjectExtend(true) 
            // 为边加上标签，使用边扩展
            .linkThreeObjectExtend(true)
            .linkThreeObject(link => {
                // extend link with text sprite
                const sprite = new SpriteText(`${link.distance}`);
                sprite.color = 'lightgrey';
                sprite.textHeight = 1.5;
                return sprite;
            })
            .linkPositionUpdate((sprite, { start, end }) => {
                const middlePos = Object.assign(...['x', 'y', 'z'].map(c => ({
                  [c]: start[c] + (end[c] - start[c]) / 2 // calc middle point
                })));
                // Position sprite
                Object.assign(sprite.position, middlePos);
            })
            // 为边加上箭头
            .linkDirectionalArrowLength(3.5)
            .linkDirectionalArrowRelPos(1)
            // 设定边的宽度
            .linkWidth(link => link.width)
            // 设置边的曲率，不设置就是直线，设置曲率对于多重边的效果比较好一点，不设置的话多重边会合并成双向直线。
            //.linkCurvature(0.25)
            // 处理结点的点击事件，选中的结点以不同的颜色标记，并高亮显示选中结点之间的边。
            .onNodeClick((node, event) => {
                // 查看'记录点击的结点'开关及'连续选取结点开关'
                var ifRecord = document.getElementById('ifRecord');
                var ifMultiSelect = document.getElementById('ifMultiSelect');
                //alert(ifRecord.checked);
                if(ifRecord.checked){
                  // multi-selection
                  if (event.ctrlKey || event.shiftKey || event.altKey || ifMultiSelect.checked) {
                      //selectedNodes.has(node) ? selectedNodes.delete(node) : selectedNodes.add(node);
                      if (selectedNodes.has(node)){
                        // 先删除结点再处理边
                        selectedNodes.delete(node);
                        if(node.links.length>0){
                            node.links.forEach(link => {
                                if (selectedNodes.has(link.source) || selectedNodes.has(link.target)){
                                    //alert('delete highlight edge!');
                                    highlightLinks.delete(link);
                                }
                            });
                        }                        
                      }
                      else{
                        // 在添加结点前先处理边
                        if(node.links.length>0){
                            node.links.forEach(link => {
                                if (selectedNodes.has(link.source) || selectedNodes.has(link.target)){
                                    //alert('add highlight edge!');
                                    highlightLinks.add(link);
                                }
                            });
                        }
                        // 添加结点
                        selectedNodes.add(node);
                      }
                  } else { // single-selection
                      const untoggle = selectedNodes.has(node) && selectedNodes.size === 1;
                      // 清空选中的结点集及高亮显示的边集
                      highlightLinks.clear();
                      selectedNodes.clear();
                      // 如果原来没有结点就添加该结点
                      if ( !untoggle){
                          selectedNodes.add(node);
                      }
                  }
                  
                  // update color of selected nodes and Edges
                  Graph.nodeColor(node => selectedNodes.has(node) ? colorNodeSelected : colorNode)
                       .linkColor(link => highlightLinks.has(link)? colorEdgeSelected : colorEdge);
                  
                  // 通知服务器选中的结点有变化
                  var nodeList = '';
                  selectedNodes.forEach(node => {
                      if (nodeList.length>0)
                        nodeList = nodeList.concat('!',node.label);
                      else
                        nodeList = node.label;
                  });
                  Shiny.setInputValue('nodes_selected', nodeList);
                }
            })
            // 设置边的颜色，开始时没有高亮的边。
            .linkColor((link) => {return colorEdge;})
            // 也可以通过指定边的颜色属性名称来指定颜色，这样可以先在igraph中处理
            //.linkColor('color')
            // 边动画演示，加亮显示的边有1个流动的点，从源到目标结点，其它边没有
            .linkDirectionalParticles(link => highlightLinks.has(link) ? 2 : 0)
            // 通过速度来表示流量，各条边的流量不同。
            .linkDirectionalParticleSpeed(link => link.paths * 0.01)
            // 边动画演示中流动小点的尺寸
            .linkDirectionalParticleWidth(3)
            // 边动画演示中流动小点的颜色，不定义就是与边的颜色一样
            .linkDirectionalParticleColor(() => 'orange')
            // 点击边时显示动画，从源到目标结点。
            .onLinkClick((link, event) =>{Graph.emitParticle(link)}); 
      
            // Spread nodes a little wider
            Graph.d3Force('charge').strength(-120);
            
            // 把Graph对象传出事件处理函数之外，以便全局引用，比如清除选择的结点与边
            mygraph = Graph;
            
            // 更新加载状态
            APPStatus.value = '网络数据已加载';
        });
        
        </script>
      "),
                           
                           tags$script(HTML("
        //接收服务器传来清除选中结点的指令。
        Shiny.addCustomMessageHandler('clearSelectedNodes', function(data) {
          try{
            // 清空 selectedNodes, highlightLinks，并设置选中源结点
            selectedNodes.clear();
            highlightLinks.clear();
            var sourceNode = gData.nodes.find(obj => {return obj.id === data});
            selectedNodes.add(sourceNode);
            // 应用前面保存的全局图对象，重新设置选中与没有选中结点的颜色
            mygraph.nodeColor(node => selectedNodes.has(node) ? colorNodeSelected : colorNode)
                   .linkColor((link) => {return colorEdge;});
            // 更新结点选择状态
            APPStatus.value = '已清除选择的结点';
          }catch(error){
            //alert(error);
          }
        });
        
      ")),
                           
                           tags$script(HTML("
        //接收服务器传来设置源结点初始视野的指令。
        Shiny.addCustomMessageHandler('setSourceNode', function(data) {
          try{
            selectedNodes.clear();
            //设置起点机场为默认选中
            var sourceNode = gData.nodes.find(obj => {return obj.id === data});
            selectedNodes.add(sourceNode);

            // 应用前面保存的全局图对象，重新设置选中与没有选中结点的颜色
            mygraph.nodeColor(node => selectedNodes.has(node) ? colorNodeSelected : colorNode);
            // 测试通过属性指定颜色
            //mygraph.nodeColor('color')

              // 设置初始焦点
              // 参阅： https://github.com/vasturiano/3d-force-graph/issues/523
              mygraph.onEngineTick(() => {
                //focusNode();
                // 设置焦距
                var distance = 320;
                var distRatio = 1 + distance/Math.hypot(sourceNode.x, sourceNode.y, sourceNode.z);
              
                mygraph.cameraPosition(
                    // new position
                    { x: sourceNode.x * distRatio, y: sourceNode.y * distRatio, z: sourceNode.z * distRatio },
                    sourceNode, // lookAt ({ x, y, z })
                    3000  // ms transition duration
                );
                // From now on, we don't want to invoke this function anymore.                
                mygraph.onEngineTick(() => {}); 
              });
              
            // 等Force Engin执行完成后，图稳定下来，自动调整焦距到看到全图。
            // https://github.com/vasturiano/3d-force-graph/issues/340
            mygraph.onEngineStop(() => {
                mygraph.zoomToFit(0,1,node =>node.id===sourceNode.id);
                // From now on, we don't want to invoke this function anymore.                
                mygraph.onEngineStop(() => {});
            });
            
            // 更新结点选择状态
            APPStatus.value = '已设自动调整焦距';


          }catch(error){
            //alert(error);
          }
        });
        
      ")),      
                           # 5/6
                           width = 10
                         )
                       )
              ),
              tabPanel("投影语句",
                       mainPanel(
                         textAreaInput("projection","投影语句", width='1000px', rows =24, resize="vertical", value =projection),
                         actionButton("excuteProjecttion", "执行投影", class = "btn-project"),
                         tags$h6(" "),
                         textOutput("projection_reults")
                       ))   
              
              
  )
)

