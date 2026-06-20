# Neo4jWorks — Neo4j Graph Data Science 应用示例集

![Neo4j](https://img.shields.io/badge/Neo4j-2026.05.0-blue)
![GDS](https://img.shields.io/badge/GDS-2026.05.0-green)
![Java](https://img.shields.io/badge/Java-21-orange)
![R](https://img.shields.io/badge/R-4.x-276DC3)
![Python](https://img.shields.io/badge/Python-3.x-3776AB)
![License](https://img.shields.io/badge/License-Apache%202.0-blue)

基于 Neo4j Graph Data Science (GDS) 库的图算法扩展插件 + 交互式网络可视化分析应用示例。

> 本仓库虽以**机场航线网络**为例，但**适用于一切网络**——金融领域银行账户间的资金转账网络、税收领域的发票交易资金网络、社交网络、供应链网络等。可参考本示例开发自己的网络分析应用。

> ⚠️ **版本说明**：本仓库的 Neo4j Community 与 GDS 库均已升级至 **2026.05.0**（最新版），`Cypher/Demo.cypher` 中的测试脚本已针对新版作了相应调整。但 Shiny APP 中嵌入的 Cypher 语句编写时基于的是 **Neo4j Community 5.x + GDS 2.5.5**（旧版），新版 GDS 的算法名称和参数可能有变化。读者在最新版上运行 Shiny APP 时，可能需要根据实际情况自行作一些调整。
> 
> 📥 **下载地址**：
> - Neo4j Community 汉化版：[https://we-yun.com/blog/prod-56.html](https://we-yun.com/blog/prod-56.html)
> - GDS 库：[https://github.com/neo4j/graph-data-science](https://github.com/neo4j/graph-data-science)

---

## 📋 项目结构

```
Neo4jWorks/
├── my-gds-ext/                 ← Neo4j GDS 图算法扩展插件 (Gradle)
│   ├── build.gradle
│   ├── src/main/java/          ← 算法源码
│   └── src/test/java/          ← 单元测试
├── my-neo4j-functions/         ← Neo4j 用户自定义函数 (Maven)
│   ├── pom.xml
│   └── src/main/java/apoc/coll/MyFunctions.java  ← 中位数函数
├── Cypher/
│   └── Demo.cypher             ← 测试算法和函数的 Cypher 脚本
├── scripts/
│   └── neo4jAirports.py        ← Python 连接 Neo4j 调用算法
├── ShinyApps/
│   ├── airports2/              ← 2D 交互式网络可视化分析
│   ├── airports3d/             ← 3D 交互式网络可视化分析
│   ├── airportsRings/          ← 3D 航路环线分析
│   └── net3d/                  ← 通用 3D 交互式网络可视化
└── README.md
```

---

## 🧠 图算法扩展 (my-gds-ext)

基于 GDS 官方 Pregel 框架开发的图算法插件，打包为 Neo4j 5.x Community 的 `.jar` 插件。

### 有向图算法（最小树形图）

| 算法 | 方向 | Cypher 调用 | 说明 |
|---|---|---|---|
| **最小树形图** | 入度 | `gds.arborescence.in.write()` | 求有向图的最小生成树（供应链场景） |
| **最小树形图** | 出度 | `gds.arborescence.out.write()` | 求有向图的最小生成树（销售链场景） |
| **K最小树形图** | 入度 | `gds.arborescence.in.k.write()` | 指定 k 个节点到源的入边最小树形图 |
| **K最小树形图** | 出度 | `gds.arborescence.out.k.write()` | 指定 k 个节点到源的出边最小树形图 |

支持 `objective: 'maximum'` 参数求**最大树形图**。

### 无向图算法（最小/最大生成树）

| 算法 | Cypher 调用 | 说明 |
|---|---|---|
| **K最小生成树** | `gds.MyKSpanningTree.write()` | 指定 k 个节点的 Kruskal 变体 |
| **K最大生成树** | `gds.MyKSpanningTree.write(objective:'maximum')` | K最大生成树 |

### 构建与部署

```bash
cd my-gds-ext
./gradlew shadowJar      # 编译打包
cp build/libs/my-gds-ext-*.jar /path/to/neo4j/plugins/   # 部署到 Neo4j
# 重启 Neo4j 后即可调用
```

---

## 🧩 用户自定义函数 (my-neo4j-functions)

| 函数 | 说明 |
|---|---|
| `apoc.coll.median([1,2,3])` | 求数组的中位数 |

> 与 `apoc.agg.median()` 不同：`apoc.agg.median` 是聚合函数（按列名），而 `apoc.coll.median` 是列表函数（按数组值）。

### 构建与部署

```bash
cd my-neo4j-functions
mvn clean package
cp target/my-neo4j-functions-*.jar /path/to/neo4j/plugins/
# 重启 Neo4j 后即可调用
```

---

## 📜 Cypher 测试脚本

`Cypher/Demo.cypher` 包含完整的测试 Cypher 语句：

- 创建测试图（Place 节点 + LINK 关系）
- 投影图到 GDS 内存图
- 调用最小生成树、K最小生成树（最大/最小方向）
- 调用最小树形图、K最小树形图（入度/出度方向）
- 加载真实机场航线数据集（来自 [neo4j-graph-examples/graph-data-science2](https://github.com/neo4j-graph-examples/graph-data-science2)）
- 测试用户自定义函数 `apoc.coll.median()`

---

## 📊 交互式可视化应用 (ShinyApps)

以中国机场航线网络为示例数据的 R Shiny 交互式应用。需安装 [R](https://www.r-project.org/) 和 [Shiny](https://shiny.posit.co/)。

### 架构

```
用户浏览器 ← [Shiny Server] ← scripts/neo4jAirports.py → Neo4j (bolt)
                           ↑
                    (reticulate 调用 Python)
```

> ⚠️ **版本兼容性**：以下 4 个 Shiny APP 中嵌入的 Cypher 语句编写于 **Neo4j Community 5.x + GDS 2.5.5** 时期，而当前仓库的 Neo4j 与 GDS 已是 **2026.05.0** 版。新版 GDS 的算法名称和参数可能有变化，因此 APP 中的 Cypher 语句在最新版上直接运行时可能报错，读者需注意甄别和调整。可参考 `Cypher/Demo.cypher` 中的新版写法进行适配。

### airports2 — 2D 交互式网络

🌐 **在线示例**：[https://jeanye.cn:8443/neo4jExamples/index.jsp](https://jeanye.cn:8443/neo4jExamples/index.jsp)

- **技术栈**：R Shiny + visNetwork + leaflet
- **功能**：选择机场，指定路径深度，2D 拓扑网络 + 地图联动展示
- **可视化**：节点按机场分类着色，边按距离着色，点击/悬浮交互

### airports3d — 3D 交互式网络

🌐 **在线示例**：[https://jeanye.cn:8443/neo4jExamples/index3D.jsp](https://jeanye.cn:8443/neo4jExamples/index3D.jsp)

- **技术栈**：R Shiny + threejs (graphjs)
- **功能**：3D 力导向图，拖拽旋转，机场信息悬浮
- **可视化**：立体球状布局，关系弧线展示

### airportsRings — 3D 航路环线分析

🌐 **在线示例**：[https://jeanye.cn:8443/neo4jExamples/indexRings.jsp](https://jeanye.cn:8443/neo4jExamples/indexRings.jsp)

- **技术栈**：R Shiny + threejs + 自定义分析
- **功能**：查找从指定机场出发的**航路环线**（起点=终点），支持：
  - 路径长度（2~6 跳）
  - 振幅过滤（各段距离的均一性）
  - 距离阈值过滤
- **分析算法**：使用 `apoc.coll.median()` 中位数函数评估环线均衡性

### net3d — 通用 3D 网络分析

🌐 **在线示例**：[https://jeanye.cn:8443/neo4jExamples/index3Dall.jsp](https://jeanye.cn:8443/neo4jExamples/index3Dall.jsp)

- **技术栈**：R Shiny + threejs + 自定义 Cypher 输入
- **通用性**：支持用户**自行编写 Cypher 语句**来：
  1. 自定义图投影（Cypher projection）
  2. 自定义子网查询（analyze query）
- **适用场景**：不仅限机场网络，可分析任何 Neo4j 中的图数据
  - 💰 银行账户资金转账网络
  - 📄 发票交易资金网络
  - 👥 社交关系网络
  - 🏭 供应链网络

---

## 🐍 Python 连接脚本

`scripts/neo4jAirports.py` 提供以下功能：

| 函数 | 功能 |
|---|---|
| `getAirLines(source, length)` | Delta-Stepping 最短路径（返回 N 跳内的节点） |
| `getAirLines2(source, length)` | 完全子网（直接匹配多跳路径） |
| `getRings(source, length, amplitude, threshold)` | 航路环线分析（使用中位数过滤） |
| `getAirports(country)` | 获取指定国家的机场列表 |
| `CypherQuery(cql)` | 执行自定义 Cypher 查询并返回结果 |
| `project(cql)` | 执行自定义 Cypher 图投影 |

---

## 🚀 快速开始

### 前提条件

- Neo4j 5.x Community + GDS 插件
- Java 21+
- Gradle 9.5+（或使用 `gradlew`）
- Maven 3.9+
- R 4.x + Shiny + shinydashboard + reticulate + visNetwork + threejs
- Python 3.x + neo4j driver + pandas

### 步骤

1. **构建并部署算法插件**
   ```bash
   cd my-gds-ext && ./gradlew shadowJar
   cd ../my-neo4j-functions && mvn clean package
   # 将两个 .jar 复制到 Neo4j plugins/ 目录，重启 Neo4j
   ```

2. **加载机场航线数据**
   ```bash
   # 在 Neo4j Browser 或 Cypher Shell 中执行 Cypher/Demo.cypher 的加载部分
   ```

3. **运行 Shiny 应用**
   ```bash
   # 方法 1: RStudio 中打开对应的 ui.R/server.R/global.R，点击 Run App
   
   # 方法 2: 命令行
   R -e "shiny::runApp('ShinyApps/airports2')"
   R -e "shiny::runApp('ShinyApps/airports3d')"
   R -e "shiny::runApp('ShinyApps/airportsRings')"
   R -e "shiny::runApp('ShinyApps/net3d')"
   ```

4. **测试算法**
   ```bash
   # 在 Neo4j Browser 或 Cypher Shell 中执行 Cypher/Demo.cypher 中的测试语句
   ```

---

## 📝 许可

Apache License 2.0 — 详见 [LICENSE](LICENSE)

---

## 🤝 贡献

欢迎提交 Issue 和 PR！无论是新算法、新可视化方式，还是文档改进。

---

*Made with 🐵 by 大圣*
