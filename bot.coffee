require("dotenv").config()
Datastore = require "nedb-promises"
_ = require "lodash"
{ v1: uuid } = require "uuid"
fastify = require("fastify") logger: true

UserDB = Datastore.create "./user.db"

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
	.on "message", (message) ->
		text = message.text()
		if text is "webhook" or text is '推送地址'
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


fastify.register require("fastify-rate-limit"), max: 100
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

start = ->
	await bot.start()
	await fastify.listen process.env.PORT or 3000
	console.log 'listen ' + process.env.PORT or 3000

start()
