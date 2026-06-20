library(reticulate)
library(sqldf)
library(igraph)
# visNetwork提供了浏览器端交互式动态展示网络的Javascript Widget，并且提供了Shiny支持。
# 它的网络图是平面的，比较适合于发票交易网络的可视化展示。
library(visNetwork)

# 确定连接Neo4j的Python脚本的目录位置
print(getwd())
location<- substr(getwd(),1,4)
# 调用Pyhton脚本连接 Neo4j, Neo4j的官方Python Driver比开源R Driver好用。
if (location != '/srv'){    # Rstudio 开发环境
  part<- '~'
}else{                       # 服务器部署环境
  part<- '..'
}
path<- paste(part,"/scripts/","neo4jAirports.py",sep="")
print(path)
#使用指定的Conda虚拟环境"openai"运行Python程序
use_condaenv(condaenv="graphrag", conda = "/usr/lib64/anaconda3/bin/conda", required = TRUE)
# 装入脚本
source_python(path)
# 调用Python函数载入国内有出发航线数据的机场列表
airports<- getAirports("CN")
