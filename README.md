# feishu-bridge

飞书 Gateway 桥接服务 — 通过飞书机器人远程控制 CodeBuddy/WorkBuddy AI 助手。

## 架构

```
飞书用户消息 → 飞书服务器 → POST /feishu/callback → feishu-bridge → CodeBuddy CLI → 返回结果
```

## 快速部署

```bash
# 1. 克隆项目
git clone <仓库地址>
cd feishu-bridge

# 2. 配置环境变量
cp .env.example .env
vim .env  # 填入 FEISHU_APP_SECRET 和 FEISHU_VERIFICATION_TOKEN

# 3. 一键部署
chmod +x deploy.sh
./deploy.sh
```

## 环境变量

| 变量 | 说明 | 必填 |
|------|------|------|
| `FEISHU_APP_ID` | 飞书应用 ID | ✅ |
| `FEISHU_APP_SECRET` | 飞书应用 Secret | ✅ |
| `FEISHU_VERIFICATION_TOKEN` | 事件订阅 Verification Token | ✅ |
| `PORT` | 服务端口（默认 3000） | ❌ |
| `CODEBUDDY_CLI_PATH` | CodeBuddy CLI 路径 | ❌ |
| `GATEWAY_MODE` | 模式：remote-control | ❌ |
| `LOG_LEVEL` | 日志级别：debug/info/warn/error | ❌ |

## Docker 部署

```bash
docker build -t feishu-bridge .
docker run -d -p 3000:3000 --env-file .env --restart always feishu-bridge
```

## 飞书后台配置

1. 飞书开放平台 → 事件订阅 → 请求地址 URL：
   ```
   http://<服务器IP>:3000/feishu/callback
   ```
2. 订阅事件：`im.message.receive_v1`（接收消息）
3. 权限申请：`im:message`、`im:message:send_as_bot`

## 手动管理

```bash
pm2 start server.js --name feishu-bridge
pm2 logs feishu-bridge
pm2 restart feishu-bridge
pm2 stop feishu-bridge
```
