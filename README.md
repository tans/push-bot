# push-bot

基于 wechaty 的微信推送机器人

关注机器人即可获得推送 API 地址

# 特点

-   代码少，百行代码实现
-   基于 Wechaty ，fastify
-   请求限制， 防止机器人账号被封，也避免消息骚扰
-   自动通过好友，自动生成接口地址

# 安装运行

1. 安装依赖 `npm install`

2. 配置参数，编辑 WECHATY_TOEKN `cp .env.example .env`

3. 运行 `node bot.js`

# 发送接口

## 地址 https://push.bot.qw360.cn/send/:token
该接口通过关注机器人获得

GET 接口方便发送文本消息

POST 接口支持复杂消息结构

```

GET https://push.bot.qw360.cn/send/:token?msg=xxx


POST https://push.bot.qw360.cn/send/:token

{
    "msg": {
        "type": "image",
        "url": "https://wimg.caidan2.com/cuimage/20210722085945_fb94ET_WechatIMG8.png"
    }
}

```

图片url仅支持 https

# 马上试用

![image](https://user-images.githubusercontent.com/543287/126447077-48823663-cf5d-433b-b51d-8096f634477d.png)
