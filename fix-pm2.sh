#!/bin/bash
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
DIR="/opt/feishu-bridge"

# 加载 nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

echo -e "${YELLOW}[1/4] 安装 PM2...${NC}"
npm install -g pm2 2>&1 | tail -3

# 获取 pm2 实际路径
PM2_PATH=$(which pm2)
echo "PM2 路径: $PM2_PATH"

echo -e "\n${YELLOW}[2/4] 写入 PATH 到 bashrc...${NC}"
NODE_BIN=$(dirname "$(which node)")
if ! grep -q "$NODE_BIN" ~/.bashrc; then
  echo "export PATH=$NODE_BIN:\$PATH" >> ~/.bashrc
  echo "已添加 $NODE_BIN 到 PATH"
fi
# 当前 session 也生效
export PATH="$NODE_BIN:$PATH"

echo -e "\n${YELLOW}[3/4] 启动 feishu-bridge...${NC}"
cd "$DIR"
pm2 delete feishu-bridge 2>/dev/null || true
pm2 start server.js --name feishu-bridge
pm2 save 2>/dev/null || true
pm2 startup 2>/dev/null || true

echo -e "\n${YELLOW}[4/4] 验证...${NC}"
sleep 3
pm2 status
echo ""
curl -s http://localhost:3000/health && echo "" || echo "健康检查失败"

echo -e "\n${GREEN}完成！${NC}"
echo "PM2 路径已写入 ~/.bashrc，重新登录后也可直接使用 pm2 命令"
