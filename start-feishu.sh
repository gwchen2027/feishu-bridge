#!/bin/bash
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
DIR="/opt/feishu-bridge"

# 加载 nvm 找到 node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NODE_BIN=$(dirname "$(which node)")
echo "Node 路径: $NODE_BIN"

# 杀掉旧进程
pkill -f "node.*server.js" 2>/dev/null || true
sleep 1

# 直接用绝对路径启动，不依赖 PM2
cd "$DIR"
nohup "$NODE_BIN/node" server.js > /var/log/feishu-bridge.log 2>&1 &
PID=$!
echo "启动 PID: $PID"

sleep 3

# 验证
if kill -0 $PID 2>/dev/null; then
  echo -e "${GREEN}进程运行中 ✓${NC}"
else
  echo -e "${RED}进程已崩溃，日志如下：${NC}"
  cat /var/log/feishu-bridge.log
  exit 1
fi

# 健康检查
echo -e "\n${YELLOW}健康检查...${NC}"
curl -s http://localhost:3000/health && echo "" || echo -e "${RED}健康检查失败${NC}"

echo ""
echo "=== 日志 ==="
tail -20 /var/log/feishu-bridge.log

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  启动完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo "查看日志: tail -f /var/log/feishu-bridge.log"
echo "停止: pkill -f 'node.*server.js'"
