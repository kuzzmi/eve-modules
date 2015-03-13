module.exports = (Eve) ->

    Eve.memory.data.smokedLast ||= null

    Eve.respond /when did I smoke\??/i, (msg) ->
        if Eve.memory.data.smokedLast?
            last = new Date Eve.memory.data.smokedLast
            now  = new Date()
            diff = new Date(now - last)

            minutesTotal = diff / 1000 // 60
            hours        = minutesTotal // 60
            minutes      = minutesTotal - hours * 60

            response   = "You've smoked "
            timeReport = ""
            
            if hours   > 0 then timeReport += "#{hours} hours "
            if minutes > 0 then timeReport += "#{minutes} minutes "

            response += timeReport + "ago"

            if hours > 0
                response += ". May be it's a good idea to go right now"

            msg.send response
        else
            msg.send "Do you smoke? Really?"

    Eve.respond /I('m| am)? go(ing)?( to)? smok(e|ing)/i, (msg) ->
        Eve.memory.data.smokedLast = new Date()
        msg.send "Bad boy. Okay..."

    Eve.respond /forget about smok(e|ing)/i, (msg) ->
        Eve.memory.data.smokedLast = null
        msg.send "Let's pretend you've never smoked."