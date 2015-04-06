exec = require 'ssh-exec'
spawn = require('child_process').spawn

{ Module, Config } = require '../../eve'

###

    "raspberry": {
        "user": "pi"
        "host": "192.168.0.9"
        "password": "raspberry"
    }

###

class HomeModule extends Module

    sshCommand: (command, root='/home/pi/bin/') ->
        if not Config.raspberry
            phrase = "And here #{@device} has to #{@action}"
            @response
                .addText phrase
                .send()
        else
            connection = exec.connection Config.raspberry
                
            exec root + command, connection
                .pipe(process.stdout)

    led: (command) ->
        com = switch command
            when 'bright' then 'led-bright'
            when 'dim'    then 'led-dim'
            else 'led ' + command

        @sshCommand com

    projector: (command) ->
        com = "proj#{command}"
        
        @sshCommand com

    projector_screen: (command) ->
        com = "screen#{command}"
        
        @sshCommand com

    theater: (command) ->
        com = "theater_#{command}"
        
        @sshCommand com
    
    vlc: (source) ->
        source = decodeURIComponent source

        spawn 'vlc', [ source, '--audio-language=en', '--fullscreen' ]
        return @response

    monitor: (command) ->
        setTimeout =>
            spawn 'xset', "dpms force #{command}".split ' '
        , 2500
                
        return @response

    music: (command) ->

        spawn 'nuvolaplayer3ctl', [ 'action', command ]
                
        return @response

    exec: ->
        if not Config.raspberry then return false

        @device = @getValue 'home_device'
        @action = @getValue 'home_action'
        @onoff = @getValue 'on_off'

        if not @action?
            @action = @onoff

        @[@device] @action

module.exports = HomeModule
