# Neo4jWorks — Neo4j Graph Data Science Application Examples

![Neo4j](https://img.shields.io/badge/Neo4j-2026.05.0-blue)
![GDS](https://img.shields.io/badge/GDS-2026.05.0-green)
![Java](https://img.shields.io/badge/Java-21-orange)
![R](https://img.shields.io/badge/R-4.x-276DC3)
![Python](https://img.shields.io/badge/Python-3.x-3776AB)
![License](https://img.shields.io/badge/License-Apache%202.0-blue)

Graph algorithm extension plugins based on Neo4j Graph Data Science (GDS), plus interactive network visualization analysis applications.

> Although this repo uses **airport route networks** as an example, it applies to **any type of network** — bank account fund transfer networks in finance, invoice transaction fund networks in taxation, social networks, supply chain networks, etc. Use these examples as a reference to build your own network analysis applications.

> ⚠️ **Version Note**: This repo's Neo4j Community and GDS library have been upgraded to **2026.05.0** (latest). The `Cypher/Demo.cypher` test scripts have been adjusted accordingly. However, the Cypher statements embedded in the Shiny apps were written for **Neo4j Community 5.x + GDS 2.5.5** (older version). Newer GDS versions may have changed algorithm names and parameters. When running Shiny apps on the latest version, you may need to make adjustments yourself.
> 
> 📥 **Downloads**:
> - Neo4j Community Edition: [https://neo4j.com/product/community-edition/](https://neo4j.com/product/community-edition/)
> - GDS Library: [https://github.com/neo4j/graph-data-science](https://github.com/neo4j/graph-data-science)

---

## 📋 Project Structure

```
Neo4jWorks/
├── my-gds-ext/                 ← GDS algorithm extension plugin (Gradle)
│   ├── build.gradle
│   ├── src/main/java/          ← algorithm source code
│   └── src/test/java/          ← unit tests
├── my-neo4j-functions/         ← Neo4j custom functions (Maven)
│   ├── pom.xml
│   └── src/main/java/apoc/coll/MyFunctions.java  ← median function
├── Cypher/
│   └── Demo.cypher             ← Cypher test scripts
├── scripts/
│   └── neo4jAirports.py        ← Python connector to Neo4j
├── ShinyApps/
│   ├── airports2/              ← 2D interactive network visualization
│   ├── airports3d/             ← 3D interactive network visualization
│   ├── airportsRings/          ← 3D route loop analysis
│   └── net3d/                  ← Generic 3D network analysis
└── README.md
```

---

## 🧠 Graph Algorithm Extensions (my-gds-ext)

Custom graph algorithm plugin built on GDS's official Pregel framework, packaged as a `.jar` plugin for Neo4j 5.x Community.

### Directed Graph Algorithms (Minimum Arborescence)

| Algorithm | Direction | Cypher Call | Description |
|---|---|---|---|
| **Minimum Arborescence** | In-degree | `gds.arborescence.in.write()` | Minimum spanning tree for digraphs (supply chain scenario) |
| **Minimum Arborescence** | Out-degree | `gds.arborescence.out.write()` | Minimum spanning tree for digraphs (sales chain scenario) |
| **K-Minimum Arborescence** | In-degree | `gds.arborescence.in.k.write()` | K-node minimum-in-arborescence |
| **K-Minimum Arborescence** | Out-degree | `gds.arborescence.out.k.write()` | K-node minimum-out-arborescence |

Supports `objective: 'maximum'` parameter for **maximum arborescence**.

### Undirected Graph Algorithms (Min/Max Spanning Tree)

| Algorithm | Cypher Call | Description |
|---|---|---|
| **K-Minimum Spanning Tree** | `gds.MyKSpanningTree.write()` | K-node Kruskal variant |
| **K-Maximum Spanning Tree** | `gds.MyKSpanningTree.write(objective:'maximum')` | K-Maximum Spanning Tree |

### Build & Deploy

```bash
cd my-gds-ext
./gradlew shadowJar             # compile & package
cp build/libs/my-gds-ext-*.jar /path/to/neo4j/plugins/   # deploy to Neo4j
# Restart Neo4j to load the plugin
```

---

## 🧩 Custom Functions (my-neo4j-functions)

| Function | Description |
|---|---|
| `apoc.coll.median([1,2,3])` | Returns the median of an array. Used primarily to detect **stable strong loops** in fund flow networks, with the variation controlled by threshold parameters. |

> Differs from `apoc.agg.median()`: `apoc.agg.median` is an aggregate function (column-based), while `apoc.coll.median` is a list function (array-based).

### Build & Deploy

```bash
cd my-neo4j-functions
mvn clean package
cp target/my-neo4j-functions-*.jar /path/to/neo4j/plugins/
# Restart Neo4j to load the plugin
```

---

## 📜 Cypher Test Script

`Cypher/Demo.cypher` contains complete test Cypher statements for:

- Creating test graphs (Place nodes + LINK relationships)
- Projecting graphs into GDS in-memory graphs
- Running Minimum Spanning Tree, K-Minimum/Maximum Spanning Tree
- Running Minimum Arborescence, K-Minimum Arborescence (in/out-degree)
- Loading real-world airport route data (from [neo4j-graph-examples/graph-data-science2](https://github.com/neo4j-graph-examples/graph-data-science2))
- Testing the custom `apoc.coll.median()` function

---

## 📊 Interactive Visualization Apps (ShinyApps)

R Shiny interactive apps using China's airport route network as sample data. Requires [R](https://www.r-project.org/) and [Shiny](https://shiny.posit.co/).

### Architecture

```
User Browser ← [Shiny Server] ← scripts/neo4jAirports.py → Neo4j (bolt)
                           ↑
                    (reticulate calls Python)
```

> ⚠️ **Version Compatibility**: The Cypher statements embedded in the 4 Shiny apps below were written for **Neo4j Community 5.x + GDS 2.5.5**, while this repo now uses **GDS 2026.05.0**. Newer GDS versions may have different algorithm names and parameters, so the Shiny app Cypher statements may not work out-of-the-box. Refer to `Cypher/Demo.cypher` for the updated syntax.

### airports2 — 2D Interactive Network

🌐 **Live Demo**: [https://jeanye.cn:8443/neo4jExamples/index.jsp](https://jeanye.cn:8443/neo4jExamples/index.jsp)

- **Stack**: R Shiny + visNetwork + leaflet
- **Features**: Select an airport, specify path depth, 2D topology network + map view
- **Visualization**: Nodes colored by airport type, edges colored by distance, click/hover interaction

### airports3d — 3D Interactive Network

🌐 **Live Demo**: [https://jeanye.cn:8443/neo4jExamples/index3D.jsp](https://jeanye.cn:8443/neo4jExamples/index3D.jsp)

- **Stack**: R Shiny + threejs (graphjs)
- **Features**: 3D force-directed graph, drag/rotate, hover airport info
- **Visualization**: Spherical node layout, curved relationship arcs

### airportsRings — 3D Route Loop Analysis

🌐 **Live Demo**: [https://jeanye.cn:8443/neo4jExamples/indexRings.jsp](https://jeanye.cn:8443/neo4jExamples/indexRings.jsp)

- **Stack**: R Shiny + threejs + custom analysis
- **Features**: Find **route loops** starting and ending at the same airport, with:
  - Path length (2–6 hops)
  - Amplitude filter (uniformity of segment distances)
  - Distance threshold filter
- **Analysis**: Uses `apoc.coll.median()` to evaluate loop uniformity

### net3d — Generic 3D Network Analysis

🌐 **Live Demo**: [https://jeanye.cn:8443/neo4jExamples/index3Dall.jsp](https://jeanye.cn:8443/neo4jExamples/index3Dall.jsp)

- **Stack**: R Shiny + threejs + custom Cypher input
- **Generality**: Users write **their own Cypher statements** to:
  1. Define custom graph projections (Cypher projection)
  2. Define custom subgraph queries (analyze query)
- **Use Cases**: Not limited to airport networks — works with any graph data in Neo4j:
  - 💰 Bank account fund transfer networks
  - 📄 Invoice transaction fund networks
  - 👥 Social relationship networks
  - 🏭 Supply chain networks

---

## 🐍 Python Connector Script

`scripts/neo4jAirports.py` provides the following functions:

| Function | Purpose |
|---|---|
| `getAirLines(source, length)` | Delta-Stepping shortest paths (returns nodes within N hops) |
| `getAirLines2(source, length)` | Full subgraph (direct multi-hop path matching) |
| `getRings(source, length, amplitude, threshold)` | Route loop analysis (with median filtering) |
| `getAirports(country)` | List airports for a given country |
| `CypherQuery(cql)` | Execute arbitrary Cypher queries and return results |
| `project(cql)` | Execute custom Cypher graph projection |

---

## ⚙️ Setup Guide

### neo4jkeys Configuration

`scripts/neo4jAirports.py` uses `from neo4j import neo4jkeys` to load custom credentials.
Create `scripts/neo4jkeys.py` manually with:

```python
user = "neo4j"       # your Neo4j username
password = "xxxx"    # your Neo4j password
```

> `neo4jkeys.py` is in `.gitignore` and will not be committed.

### R Package Dependencies

Required R packages (run `install.packages()` in R):

```r
install.packages(c(
  "shiny", "shinydashboard", "shinythemes", "shinyWidgets",
  "visNetwork", "leaflet", "threejs",
  "reticulate", "data.table", "dplyr", "DT"
))
```

### Linux System Dependencies

The following system packages may be needed when compiling the R packages above:

```bash
# Ubuntu / Debian
sudo apt install libcurl4-openssl-dev libssl-dev libxml2-dev \
                 libudunits2-dev libgdal-dev libgeos-dev libproj-dev
```

> Neo4j Community installation and configuration is outside the scope of this guide — please refer to official documentation.

### Environment Setup References

- [Setting Up a GPU Linux Server Deep Learning Environment on WSL](https://zhuanlan.zhihu.com/p/694938539) (Chinese)
- [Compiling and Installing R on Ubuntu 22](https://zhuanlan.zhihu.com/p/695584437) (Chinese)
- [Integrating Java EE, R and Python on WSL2 Ubuntu22](https://zhuanlan.zhihu.com/p/700126962) (Chinese)

---

## 🚀 Quick Start

### Prerequisites

- Neo4j 5.x Community + GDS plugin
- Java 21+
- Gradle 9.5+ (or use `gradlew`)
- Maven 3.9+
- R 4.x + packages listed above
- Python 3.x + neo4j driver + pandas

### Steps

1. **Build and deploy algorithm plugins**
   ```bash
   cd my-gds-ext && ./gradlew shadowJar
   cd ../my-neo4j-functions && mvn clean package
   # Copy both .jar files to Neo4j plugins/, restart Neo4j
   ```

2. **Load airport route data**
   ```bash
   # Run the data loading section of Cypher/Demo.cypher in Neo4j Browser or Cypher Shell
   ```

3. **Run Shiny apps**
   ```bash
   # Method 1: Open ui.R/server.R/global.R in RStudio, click Run App
   
   # Method 2: Command line
   R -e "shiny::runApp('ShinyApps/airports2')"
   R -e "shiny::runApp('ShinyApps/airports3d')"
   R -e "shiny::runApp('ShinyApps/airportsRings')"
   R -e "shiny::runApp('ShinyApps/net3d')"
   ```

4. **Test algorithms**
   ```bash
   # Run test statements from Cypher/Demo.cypher in Neo4j Browser or Cypher Shell
   ```

---

## 📚 References

### Articles

- [Learning the Chu-Liu/Edmonds Algorithm for Minimum Arborescence in Python](https://www.meipian.cn/3fj0hqmk) (Chinese)
- [Developing Custom Neo4j Procedures: K-Minimum Spanning Tree](https://www.meipian.cn/3gj6iqhz) (Chinese)
- [Shiny Network Analysis App Walkthrough](https://www.meipian.cn/445rl90n) (Chinese)
- [Airport Route Loop Analysis](https://www.meipian.cn/451a6tnz) (Chinese)
- [Using Neo4j Custom Functions and Procedures in Network Analysis](https://www.meipian.cn/459u8wpz) (Chinese)

### Zhuanlan (Chinese)

- [Updating Neo4j Open Graph Data Science Extension](https://zhuanlan.zhihu.com/p/677004443)
- [Developing Neo4j Open GDS 2.5 Extension Algorithms and Procedures](https://zhuanlan.zhihu.com/p/677746295)
- [Neo4j Community 5.x + Open GDS 2.5 Minimum Arborescence](https://zhuanlan.zhihu.com/p/678160388)
- [Chapter 17: Neo4j Graph Database Application Development, Sections 1–2](https://zhuanlan.zhihu.com/p/680079397)
- [Chapter 17: Neo4j Graph Database Application Development, Section 3](https://zhuanlan.zhihu.com/p/680083515)
- [Chapter 17: Neo4j Graph Database Application Development, Section 4](https://zhuanlan.zhihu.com/p/680085122)
- [Generic 3D Network Analysis Shiny App Example](https://zhuanlan.zhihu.com/p/703509660)

### Books

- [Tax Big Data Analysis Illustrated](https://jeanye.cn/taxanalysis.html) (Chinese)
- [Mastering Shiny (Translation)](https://jeanye.cn/masteringshiny.html) (Chinese)

---

## 📝 License

Apache License 2.0 — see [LICENSE](LICENSE)

---

## 🤝 Contributing

Issues and PRs are welcome! Whether it's new algorithms, new visualization approaches, or documentation improvements.

---

*Made with 🐵 by Jean*
