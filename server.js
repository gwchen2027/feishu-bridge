const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const { exec } = require('child_process');
require('dotenv').config();

// ============================================
// 飞书 Gateway 桥接服务
// 模式：remote-control（远程控制 CodeBuddy）
// ============================================

const app = express();
app.use(express.json());

// ---------- 配置 ----------
const {
  FEISHU_APP_ID,
  FEISHU_APP_SECRET,
  FEISHU_VERIFICATION_TOKEN,
  PORT = 3000,
  CODEBUDDY_CLI_PATH = 'codebuddy',
  GATEWAY_MODE = 'remote-control',
  LOG_LEVEL = 'info',
} = process.env;

// ---------- 日志 ----------
const logger = {
  debug: (...args) => LOG_LEVEL === 'debug' && console.log('[DEBUG]', ...args),
  info: (...args) => console.log('[INFO]', ...args),
  warn: (...args) => console.warn('[WARN]', ...args),
  error: (...args) => console.error('[ERROR]', ...args),
};

// ---------- 飞书 Access Token ----------
let tenantAccessToken = null;
let tokenExpiresAt = 0;

async function getTenantAccessToken() {
  if (tenantAccessToken && Date.now() < tokenExpiresAt) {
    return tenantAccessToken;
  }
  try {
    const res = await axios.post(
      'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal',
      { app_id: FEISHU_APP_ID, app_secret: FEISHU_APP_SECRET }
    );
    tenantAccessToken = res.data.tenant_access_token;
    tokenExpiresAt = Date.now() + (res.data.expire - 300) * 1000; // 提前5分钟刷新
    logger.info('飞书 Access Token 已刷新');
    return tenantAccessToken;
  } catch (err) {
    logger.error('获取飞书 Token 失败:', err.message);
    return null;
  }
}

// ---------- 飞书消息回复 ----------
async function replyMessage(messageId, content) {
  const token = await getTenantAccessToken();
  if (!token) return;
  try {
    await axios.post(
      'https://open.feishu.cn/open-apis/im/v1/messages/' + messageId + '/reply',
      {
        content: JSON.stringify({ text: String(content) }),
        msg_type: 'text',
      },
      { headers: { Authorization: `Bearer ${token}` } }
    );
  } catch (err) {
    logger.error('回复消息失败:', err.message);
  }
}

// ---------- CodeBuddy CLI 执行 ----------
function executeCodeBuddy(prompt) {
  return new Promise((resolve) => {
    const cmd = `${CODEBUDDY_CLI_PATH} -p "${prompt.replace(/"/g, '\\"')}"`;
    logger.debug('执行命令:', cmd);
    exec(cmd, { timeout: 120000, maxBuffer: 1024 * 1024 }, (err, stdout, stderr) => {
      if (err) {
        logger.error('CLI 执行错误:', err.message);
        resolve(`执行出错: ${err.message}\n${stderr || ''}`.slice(0, 2000));
      } else {
        resolve((stdout || '执行完成（无输出）').slice(0, 2000));
      }
    });
  });
}

// ---------- 飞书事件回调 ----------
app.post('/feishu/callback', async (req, res) => {
  const body = req.body;

  // URL 验证（飞书首次配置时）
  if (body.type === 'url_verification') {
    const token = body.token;
    if (token !== FEISHU_VERIFICATION_TOKEN) {
      return res.status(403).json({ msg: 'invalid token' });
    }
    // 飞书会发 challenge，需返回加密后的 challenge
    const challenge = body.challenge;
    return res.json({ challenge });
  }

  // 事件回调验证
  if (body.header) {
    const eventType = body.header.event_type;
    const event = body.event;
    const messageId = event?.message?.message_id;

    logger.info('收到事件:', eventType);

    if (eventType === 'im.message.receive_v1') {
      const msgContent = event.message?.content;
      let text = '';
      try {
        const parsed = JSON.parse(msgContent);
        text = parsed.text || '';
      } catch {
        text = msgContent || '';
      }

      if (text.trim()) {
        logger.info('收到消息:', text.slice(0, 100));
        await replyMessage(messageId, `收到指令，正在处理...\n\n> ${text.slice(0, 200)}`);

        const result = await executeCodeBuddy(text);
        await replyMessage(messageId, result);
      }
    }
  }

  res.json({ code: 0 });
});

// ---------- 健康检查 ----------
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    mode: GATEWAY_MODE,
    app_id: FEISHU_APP_ID?.slice(0, 8) + '***',
    uptime: process.uptime(),
  });
});

// ---------- 启动 ----------
app.listen(PORT, () => {
  logger.info('========================================');
  logger.info(`飞书 Gateway 桥接服务已启动`);
  logger.info(`端口: ${PORT}`);
  logger.info(`模式: ${GATEWAY_MODE}`);
  logger.info(`回调地址: http://<服务器IP>:${PORT}/feishu/callback`);
  logger.info('========================================');
});
