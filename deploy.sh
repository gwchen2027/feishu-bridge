#!/bin/bash
# ============================================
# 飞书 Gateway 桥接服务 - 一键部署脚本
# 适用于 Ubuntu/CentOS 服务器
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  飞书 Gateway 桥接服务 - 部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 1. 检查 Node.js
echo -e "\n${YELLOW}[1/6] 检查 Node.js...${NC}"
if ! command -v node &>/dev/null; then
  echo -e "${RED}未检测到 Node.js，请先安装 nvm 和 Node.js${NC}"
  echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
  echo "nvm install 22"
  exit 1
fi
echo "Node.js $(node -v) ✓"

# 2. 安装依赖
echo -e "\n${YELLOW}[2/6] 安装依赖...${NC}"
npm install --production
echo -e "${GREEN}依赖安装完成 ✓${NC}"

# 3. 检查 .env
echo -e "\n${YELLOW}[3/6] 检查配置文件...${NC}"
if [ ! -f .env ]; then
  echo -e "${YELLOW}未找到 .env，从 .env.example 复制...${NC}"
  cp .env.example .env
  echo -e "${RED}⚠ 请编辑 .env 填入真实配置！${NC}"
  echo "  FEISHU_APP_SECRET=你的AppSecret"
  echo "  FEISHU_VERIFICATION_TOKEN=你的VerificationToken"
  exit 1
fi
echo ".env 已就绪 ✓"

# 4. 安装 PM2（如未安装）
echo -e "\n${YELLOW}[4/6] 检查 PM2...${NC}"
if ! command -v pm2 &>/dev/null; then
  npm install -g pm2
fi
echo "PM2 已就绪 ✓"

# 5. 启动服务
echo -e "\n${YELLOW}[5/6] 启动服务...${NC}"
pm2 delete feishu-bridge 2>/dev/null || true
pm2 start server.js --name feishu-bridge
pm2 save
echo -e "${GREEN}服务已启动 ✓${NC}"

# 6. 显示状态
echo -e "\n${YELLOW}[6/6] 服务状态...${NC}"
pm2 status feishu-bridge
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "查看日志: pm2 logs feishu-bridge"
echo "重启服务: pm2 restart feishu-bridge"
echo "停止服务: pm2 stop feishu-bridge"
echo ""
echo "⚠ 下一步："
echo "  1. 在腾讯云安全组开放端口 3000"
echo "  2. 飞书开发者后台配置事件订阅 URL:"
echo "     http://<服务器IP>:3000/feishu/callback"
