exec = require 'ssh-exec'

{ Module, Config } = require '../../eve'

###

    "raspberry": {
        "user": "pi"
        "host": "192.168.0.9"
        "password": "raspberry"
    }

###

class HomeModule extends Module

    led: (command) ->

        root = '/home/pi/bin/'

        com = switch command
            when 'bright' then 'led-bright'
            when 'dim'    then 'led-dim'
            else 'led ' + command
        
        if not Config.raspberry
            phrase = "And here #{@device} has to #{@action}"
            @response
                .addText phrase
                .send()
        else
            connection = exec.connection raspberry
            
            exec root + com, connection
                .pipe(process.stdout)

    theater: (command) ->

        root = '/home/pi/bin/'

        com = "theater_#{command}"
        
        if not Config.raspberry
            phrase = "And here #{@device} has to turn #{@action}"
            @response
                .addText phrase
                .addVoice phrase
                .send()
        else
            connection = exec.connection raspberry

            exec root + com, connection
                .pipe(process.stdout)
    
    exec: ->

        @device = @getValue 'home_device'
        @action = @getValue 'home_action'

        @[@device] @action

module.exports = HomeModule