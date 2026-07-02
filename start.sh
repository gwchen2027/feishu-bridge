#!/bin/bash
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
DIR="/opt/feishu-bridge"
LOG="$DIR/feishu-bridge.log"

echo -e "${GREEN}========== feishu-bridge 启动 ==========${NC}"

# 找 node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NODE_CMD=$(which node 2>/dev/null || echo "/usr/bin/node")
echo "Node: $NODE_CMD ($($NODE_CMD -v 2>/dev/null || echo 'unknown'))"

# 确保目录和文件存在
mkdir -p "$DIR"
touch "$LOG"
echo "目录: $DIR"
echo "日志: $LOG"
ls -la "$DIR"

# 杀旧进程
pkill -f "node.*server.js" 2>/dev/null || true
sleep 1

# 启动
cd "$DIR"
echo "启动中..."
$NODE_CMD server.js > "$LOG" 2>&1 &
PID=$!
echo "PID: $PID"
sleep 3

# 检查
if kill -0 $PID 2>/dev/null; then
  echo -e "${GREEN}进程运行中 PID=$PID ✓${NC}"
else
  echo -e "${RED}进程崩溃${NC}"
fi

echo "=== 日志 ==="
cat "$LOG"

echo ""
echo "=== 健康检查 ==="
curl -s http://localhost:3000/health || echo "失败"
