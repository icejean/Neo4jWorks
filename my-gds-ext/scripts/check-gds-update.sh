#!/usr/bin/env bash
# ============================================================
# check-gds-update.sh — 检查 GDS / Neo4j 最新版本
#
# 从 Maven Central 查询最新发布的 GDS 和 Neo4j 版本，
# 与本地 VERSION 文件对比，提示是否需要升级。
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$PROJECT_DIR/VERSION"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 检查 GDS / Neo4j 最新版本..."
echo ""

# 读取当前版本
source "$VERSION_FILE" 2>/dev/null || true

# ---------- GDS ----------
echo "📦 GDS (org.neo4j.gds:proc)"
echo "  └ 当前: $GDS_VERSION"

LATEST_GDS=$(curl -s --compressed \
    "https://search.maven.org/solrsearch/select?q=g:org.neo4j.gds+AND+a:proc&rows=1&wt=json" \
    2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
docs = d.get('response', {}).get('docs', [])
if docs:
    print(docs[0].get('latestVersion', 'unknown'))
else:
    print('unknown')
" 2>/dev/null || echo "fetch_error")

if [ "$LATEST_GDS" = "fetch_error" ] || [ "$LATEST_GDS" = "unknown" ]; then
    echo -e "  └ ${YELLOW}⚠  无法从 Maven Central 获取最新版本${NC}"
else
    echo "  └ 最新: $LATEST_GDS"
    if [ "$LATEST_GDS" != "$GDS_VERSION" ]; then
        echo -e "  └ ${YELLOW}⚡ 有新版本！建议升级: $GDS_VERSION → $LATEST_GDS${NC}"
    else
        echo -e "  └ ${GREEN}✓ 已是最新${NC}"
    fi
fi
echo ""

# ---------- Neo4j ----------
echo "🗄️ Neo4j (org.neo4j:neo4j)"
echo "  └ 当前: $NEO4J_VERSION"

LATEST_NEO4J=$(curl -s --compressed \
    "https://search.maven.org/solrsearch/select?q=g:org.neo4j+AND+a:neo4j&rows=1&wt=json" \
    2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
docs = d.get('response', {}).get('docs', [])
if docs:
    print(docs[0].get('latestVersion', 'unknown'))
else:
    print('unknown')
" 2>/dev/null || echo "fetch_error")

if [ "$LATEST_NEO4J" = "fetch_error" ] || [ "$LATEST_NEO4J" = "unknown" ]; then
    echo -e "  └ ${YELLOW}⚠  无法从 Maven Central 获取最新版本${NC}"
else
    echo "  └ 最新: $LATEST_NEO4J"
    # 比较（仅当当前版本不是 range 表达式时）
    if echo "$NEO4J_VERSION" | grep -q '\.+$'; then
        BASE_VERSION=$(echo "$NEO4J_VERSION" | sed 's/\.+$//')
        # check if latest starts with base version
        if echo "$LATEST_NEO4J" | grep -q "^$BASE_VERSION"; then
            echo -e "  └ ${GREEN}✓ 版本范围已覆盖最新${NC}"
        else
            echo -e "  └ ${YELLOW}⚡ 检查版本范围: $BASE_VERSION.x → 最新 $LATEST_NEO4J${NC}"
        fi
    else
        if [ "$LATEST_NEO4J" != "$NEO4J_VERSION" ]; then
            echo -e "  └ ${YELLOW}⚡ 有新版本！$NEO4J_VERSION → $LATEST_NEO4J${NC}"
        else
            echo -e "  └ ${GREEN}✓ 已是最新${NC}"
        fi
    fi
fi
echo ""

# ---------- 建议 ----------
cat <<'EOF'
💡 升级步骤:
   1. 更新 VERSION 中的 GDS_VERSION、NEO4J_VERSION
   2. 运行 ./gradlew build 验证兼容性
   3. 检查 GDS 更新日志中是否有 Breaking Changes
   4. 修复可能的 API 变更
   5. 重新打包: ./gradlew shadowJar

EOF
