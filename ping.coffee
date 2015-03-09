module.exports = (robot) ->
    regex = new RegExp("#{robot.name},? ping$", "i")

    robot.hear regex, (msg) ->
        msg.reply 'Pong'