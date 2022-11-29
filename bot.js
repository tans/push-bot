require("dotenv").config();

let Datastore = require("nedb-promises");

const { WechatyBuilder } = require("wechaty");
let { FileBox } = require("file-box");
let { v1: uuid } = require("uuid");

let _ = require("lodash");

let fastify = require("fastify")({
    logger: true,
});

let UserDB = Datastore.create("./users.db");
let RoomDB = Datastore.create("./rooms.db");

// let { PuppetWechat4u } = require("wechaty-puppet-wechat4u");

// let { EventLogger } = require("wechaty-plugin-contrib");

let sleep = function () {
    return new Promise(function (resolve) {
        return setTimeout(resolve, _.random(1.2, 3.2) * 1000);
    });
};

bot = WechatyBuilder.build({
    name: "bot", // generate xxxx.memory-card.json and save login data for the next login
    puppet: "wechaty-puppet-wechat4u",
});

// let bot = new PuppetWechat4u();
bot.on("scan", function (qrcode) {
    console.log(qrcode);
    if (qrcode) {
        return require("qrcode-terminal").generate(qrcode, {
            small: true,
        });
    }
})
    .on("friendship", async function (friendship) {
        var contact;
        // 自动通过好友， 并发送拉入群提醒
        await sleep();
        switch (friendship.type()) {
            case bot.Friendship.Type.Receive:
                return await friendship.accept();
            case bot.Friendship.Type.Confirm:
                contact = friendship.contact();
                return await sendWebhook(contact);
        }
    })
    .on("room-join", async function (room, inviteeList, inviter) {
        var i, invitee, len, results;
        results = [];
        for (i = 0, len = inviteeList.length; i < len; i++) {
            invitee = inviteeList[i];
            if (invitee.self()) {
                // unless room.payload.ownerId is inviter.id
                //   return inviter.say "仅限群主邀请才可获得推送地址"
                await room.say(
                    "大家好,我是推送精灵, 通过接口可以控制我发送消息到群上."
                );
                results.push(await sendRoomWebHook(inviter, room));
            } else {
                results.push(void 0);
            }
        }
        return results;
    })
    .on("room-invite", async function (roomInvitation) {
        return await roomInvitation.accept();
    })
    .on("message", async function (message) {
        var text;
        text = message.text();
        if (text === "webhook" || text === "推送地址") {
            return await sendWebhook(message.talker());
        }
    })
    .on("error", console.error);

let sendWebhook = async function (contact) {
    var _send, token, user;
    user = await UserDB.findOne({
        contactid: contact.id,
    });
    _send = async function (token) {
        return await contact.say(
            `发送地址: ${process.env.DOMAIN}/send/${token}?msg=xxx`
        );
    };
    if (user) {
        return await _send(user.token);
    }
    token = uuid();
    await UserDB.insert({
        contactid: contact.id,
        token: token,
    });
    return await _send(token);
};

let sendRoomWebHook = async function (contact, room) {
    var _send, r, token;
    _send = async function (token) {
        return await room.say(
            `发送地址: ${process.env.DOMAIN}/room/${token}?msg=xxx`
        );
    };
    r = await RoomDB.findOne({
        contactid: contact.id,
    });
    if (r) {
        return await _send(r.token);
    }
    token = uuid();
    await RoomDB.insert({
        roomid: room.id,
        token: token,
        contactid: contact.id,
    });
    return await _send(token);
};

fastify.register(require("fastify-rate-limit"), {
    max: 100,
    global: false,
});

fastify.get(
    "/send/:token",
    {
        config: {
            rateLimit: {
                max: 10,
                keyGenerator: function (req) {
                    return req.params.token;
                },
            },
        },
    },
    async function (request, reply) {
        var contact, msg, token, user;
        ({ msg } = request.query);
        ({ token } = request.params);
        user = await UserDB.findOne({
            token: token,
        });
        if (!user) {
            return {
                status: false,
                msg: "token not exists",
            };
        }
        contact = bot.Contact.load(user.contactid);
        contact.say(msg);
        return {
            status: true,
        };
    }
);

fastify.get(
    "/room/:token",
    {
        config: {
            rateLimit: {
                max: 10,
                keyGenerator: function (req) {
                    return req.params.token;
                },
            },
        },
    },
    async function (request, reply) {
        var msg, room, token;
        ({ msg } = request.query);
        ({ token } = request.params);
        room = await RoomDB.findOne({
            token: token,
        });
        if (!room) {
            return {
                status: false,
                msg: "room token not exists",
            };
        }
        room = bot.Room.load(room.roomid);
        room.say(msg);
        return {
            status: true,
        };
    }
);

fastify.post(
    "/send/:token",
    {
        config: {
            rateLimit: {
                max: 10,
                keyGenerator: function (req) {
                    return req.params.token;
                },
            },
        },
    },
    async function (request, reply) {
        var contact, image, msg, token, user;
        ({ msg } = request.body);
        ({ token } = request.params);
        user = await UserDB.findOne({
            token: token,
        });
        if (!user) {
            return {
                status: false,
                msg: "token not exists",
            };
        }
        contact = bot.Contact.load(user.contactid);
        if (typeof msg === "string") {
            await contact.say(msg);
            return {
                status: true,
            };
        }
        if (msg.type === "image") {
            image = FileBox.fromUrl(msg.url);
            await contact.say(image);
            return {
                status: true,
            };
        }
        return {
            status: false,
            msg: "unsupported msg type",
        };
    }
);

let start = async function () {
    await bot.start();
    await fastify.listen(process.env.PORT || 3000);
    return console.log("listen " + process.env.PORT || 3000);
};

start();
