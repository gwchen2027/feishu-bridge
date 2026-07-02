#!/bin/bash
# feishu-bridge 诊断修复脚本
set +e
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
DIR="/opt/feishu-bridge"

echo -e "${YELLOW}=== 1. 检查目录 ===${NC}"
ls -la "$DIR" 2>&1 || { echo -e "${RED}目录不存在！请先运行部署脚本${NC}"; exit 1; }

echo -e "\n${YELLOW}=== 2. 检查 Node.js ===${NC}"
which node 2>&1 && node -v 2>&1 || echo -e "${RED}Node.js 未安装${NC}"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null
which node 2>&1 && node -v 2>&1

echo -e "\n${YELLOW}=== 3. 检查 .env ===${NC}"
cat "$DIR/.env" 2>&1

echo -e "\n${YELLOW}=== 4. 检查依赖 ===${NC}"
ls "$DIR/node_modules" 2>/dev/null | head -5 || echo -e "${RED}node_modules 不存在，正在安装...${NC}"

echo -e "\n${YELLOW}=== 5. 停止旧进程 ===${NC}"
pm2 delete feishu-bridge 2>/dev/null
pkill -f "node.*server.js" 2>/dev/null
sleep 2

echo -e "\n${YELLOW}=== 6. 直接启动测试 ===${NC}"
cd "$DIR"
node server.js &
PID=$!
sleep 3

echo -e "\n${YELLOW}=== 7. 测试健康检查 ===${NC}"
curl -s http://localhost:3000/health 2>&1 || echo -e "${RED}健康检查失败${NC}"

echo -e "\n${YELLOW}=== 8. 进程状态 ===${NC}"
ps aux | grep "[n]ode.*server" 2>&1

echo -e "\n${YELLOW}=== 9. 如果进程已退出，查看错误 ===${NC}"
kill -0 $PID 2>/dev/null && echo -e "${GREEN}进程运行中 PID=$PID${NC}" || echo -e "${RED}进程已崩溃${NC}"

echo -e "\n${YELLOW}=== 10. 用 PM2 守护启动 ===${NC}"
npm install -g pm2 2>/dev/null
pm2 start server.js --name feishu-bridge --cwd "$DIR" 2>&1
pm2 save 2>/dev/null
pm2 startup 2>/dev/null
pm2 status 2>&1

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  诊断完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo "查看日志: pm2 logs feishu-bridge"
echo "编辑配置: vim $DIR/.env"
