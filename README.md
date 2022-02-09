# push-bot

推送精灵 - 基于 wechaty 的微信推送机器人

关注机器人即可获得推送 API 地址

## 特点
- 支持推送到个人微信和企微群
- 代码少，百余行代码实现
- 基于 Wechaty ，fastify
- 请求限制， 防止机器人账号被封，也避免消息骚扰
- 自动通过好友，自动生成接口地址

## 安装运行

1. 安装依赖 `npm install`

2. 配置参数，编辑 WECHATY_TOEKN `cp .env.example .env`

3. 运行 `node bot.js`

## 发送到个人接口

### 地址 https://push.bot.qw360.cn/send/:token

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

图片 url 仅支持 https

## 发送到群接口

邀请机器人入群即可获得推送接口地址

注意企业微信无法进入个微群，拉入群聊有以下途径

1. 邀请精灵发起一个新的群聊，自动生成企业微信群。（新拉的群注意随便发条消息激活一下）
2. 邀请进入已有企业外部群， 并且选择联系人中从 “企业微信联系人“ 二级菜单进入选择


```

GET https://push.bot.qw360.cn/room/:token?msg=xxx

```

## 马上试用

<img src="https://user-images.githubusercontent.com/543287/126447077-48823663-cf5d-433b-b51d-8096f634477d.png" width="180px"/>


## 其他项目

### 每日推送 ToDoList
查看项目 [PushTodo](https://github.com/tans/push-todo)

### 字节猎人 微信群文字游戏 （已暂停运行）
查看项目 [ByteHunter](https://github.com/tans/byte-hunter)

### 其他机器人项目

[更多机器人](http://bh.bot.qw360.cn/about)


### 更多服务

单独部署建群精灵
合约币价异动检测推送

联系开发者微信 tianshe00
