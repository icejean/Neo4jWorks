# My GDS Extensions

自定义 Neo4j Graph Data Science 算法插件项目。

基于 GDS 官方 [pregel-bootstrap](https://github.com/neo4j/graph-data-science/tree/2026.05.0/examples/pregel-bootstrap) 模板，
支持在最新 Neo4j 5.x Community 上运行自研图算法。

## 项目结构

```
my-gds-ext/
├── build.gradle           # Gradle 构建配置
├── settings.gradle        # 项目设置
├── gradlew / gradlew.bat  # Gradle Wrapper（无需系统安装 Gradle）
├── VERSION                # 当前依赖版本定义
├── scripts/
│   └── check-gds-update.sh # 检查 GDS 和 Neo4j 最新版本
├── src/
│   ├── main/java/com/mycompany/gds/  # 算法源码
│   └── test/java/com/mycompany/gds/  # 单元测试
└── lib/                    # 编译产物
```

## 快速开始

### 首次构建

```bash
# 初始化 Gradle Wrapper（一行命令）
gradle wrapper --gradle-version=9.5.0

# 编译打包
./gradlew shadowJar

# 产物在 build/libs/ 下
ls build/libs/my-gds-ext-*.jar
```

### 部署到 Neo4j

将生成的 `my-gds-ext-*.jar` 复制到 Neo4j 的 `plugins/` 目录，重启数据库：

```bash
cp build/libs/my-gds-ext-*.jar /path/to/neo4j/plugins/
```

### 测试算法

在 Neo4j Browser 或 Cypher Shell 中：

```cypher
// 投影图
CALL gds.graph.project('myGraph', '*', '*')

// 运行自定义算法
CALL my.algorithm.stream('myGraph', { maxIterations: 100 })
YIELD nodeId, value
RETURN nodeId, value
```

## 追踪 GDS 版本更新

```bash
# 检查是否有新版本
bash scripts/check-gds-update.sh

# 更新依赖版本
# 1. 修改 VERSION 文件中的版本号
# 2. 运行 ./gradlew build 以验证兼容性
```

## 添加新算法

参考 GDS Pregel 框架的注解模式：

1. 创建实现 `PregelComputation` 的 Java 类
2. 用 `@PregelProcedure` 注解声明算法名称和模式
3. 定义配置接口（继承 `PregelProcedureConfig`）
4. 运行 `./gradlew shadowJar` 编译

## 依赖说明

| 依赖 | 当前版本 | 说明 |
|---|---|---|
| GDS | 2.27.0 | 图算法库 |
| Neo4j | 2026.02.+ | 图数据库 |
| Gradle | 9.5.0 | 构建工具 |
| Java | 21+ | JDK 版本 |

## 与 GDS 主仓库的关系

- GDS 版本发布时，本项目只需更新 `VERSION` 文件中的版本号
- 编译时从 Maven Central 拉取 GDS 的 `compileOnly` 依赖
- 自研算法通过 `@PregelProcedure` 等 GDS 注解与主库解耦
- 不需要 fork 或修改 GDS 主仓库代码

原理：GDS 官方将算法模块发布到 Maven Central（`org.neo4j.gds:*`），外部项目通过 `compileOnly`
依赖这些模块，利用 Java 注解处理器在编译期生成 Neo4j 存储过程骨架，最终打包为独立 JAR 插件。
