require("dotenv").config()
Datastore = require "nedb-promises"
{ FileBox } = require "file-box"
{ v1: uuid } = require "uuid"
_ = require "lodash"
fastify = require("fastify") logger: true

UserDB = Datastore.create "./user.db"
RoomDB = Datastore.create "./room.db"

{ Wechaty, ScanStatus } = require "wechaty"
{ EventLogger } = require "wechaty-plugin-contrib"

sleep = ->
  new Promise (resolve) ->
    setTimeout resolve, _.random(1.2, 3.2) * 1000

bot = new Wechaty(
  puppet: "wechaty-puppet-service"
  puppetOptions:
    token: process.env.WECHATY_TOEKN
)

bot
  .use EventLogger()
  .on "scan", (qrcode, status) ->
    if status is ScanStatus.Waiting and qrcode
      require("qrcode-terminal").generate qrcode, small: true
  .on "friendship", (friendship) ->
    # 自动通过好友， 并发送拉入群提醒
    await sleep()
    switch friendship.type()
      when bot.Friendship.Type.Receive
        await friendship.accept()

      when bot.Friendship.Type.Confirm
        contact = friendship.contact()

        await sendWebhook contact
  .on "room-join", (room, inviteeList, inviter) ->
    for invitee in inviteeList
      if invitee.self()
        # unless room.payload.ownerId is inviter.id
        #   return inviter.say "仅限群主邀请才可获得推送地址"
        await room.say "大家好,我是推送精灵, 通过接口可以控制我发送消息到群上."
        await sendRoomWebHook inviter, room
  .on "room-invite", (roomInvitation) ->
    await roomInvitation.accept()
  .on "message", (message) ->
    text = message.text()
    if text is "webhook" or text is "推送地址"
      await sendWebhook message.talker()

sendWebhook = (contact) ->
  user = await UserDB.findOne contactid: contact.id
  _send = (token) ->
    return await contact.say """
			发送地址: #{process.env.DOMAIN}/send/#{token}?msg=xxx
		"""
  if user
    return await _send user.token
  token = uuid()
  await UserDB.insert
    contactid: contact.id
    token: token

  return await _send token

sendRoomWebHook = (contact, room) ->
  _send = (token) ->
    return await room.say """
      发送地址: #{process.env.DOMAIN}/room/#{token}?msg=xxx
    """
  r = await RoomDB.findOne contactid: contact.id

  if r
    return await _send r.token
  token = uuid()

  await RoomDB.insert
    roomid: room.id
    token: token
    contactid: contact.id
  return await _send token

fastify.register require("fastify-rate-limit"),
  max: 100
  global: false

fastify.get(
  "/send/:token"
,
  config:
    rateLimit:
      max: 10
      keyGenerator: (req) ->
        return req.params.token
,
  (request, reply) ->
    { msg } = request.query
    { token } = request.params
    user = await UserDB.findOne token: token
    return status: false, msg: "token not exists" unless user

    contact = bot.Contact.load user.contactid
    contact.say msg
    return
      status: true
)

fastify.get(
  "/room/:token"
,
  config:
    rateLimit:
      max: 10
      keyGenerator: (req) ->
        return req.params.token
,
  (request, reply) ->
    { msg } = request.query
    { token } = request.params
    room = await RoomDB.findOne token: token
    return status: false, msg: "room token not exists" unless room

    room = bot.Room.load room.roomid
    room.say msg
    return
      status: true
)

fastify.post(
  "/send/:token"
,
  config:
    rateLimit:
      max: 10
      keyGenerator: (req) ->
        return req.params.token
,
  (request, reply) ->
    { msg } = request.body
    { token } = request.params
    user = await UserDB.findOne token: token
    return status: false, msg: "token not exists" unless user

    contact = bot.Contact.load user.contactid

    if typeof msg is "string"
      await contact.say msg
      return
        status: true

    if msg.type is "image"
      image = FileBox.fromUrl msg.url
      await contact.say image
      return
        status: true

    return status: false, msg: "unsupported msg type"
)

start = ->
  await bot.start()
  await fastify.listen process.env.PORT or 3000
  console.log "listen " + process.env.PORT or 3000

start()
