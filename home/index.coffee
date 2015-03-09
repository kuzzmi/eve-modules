exec = require 'ssh-exec'

{ Module } = require '../../eve'

class HomeModule extends Module

    led: (command) ->
        params = 
            user     : 'pi'
            host     : '192.168.0.9'
            password : 'raspberry'

        connection = exec.connection params

        root = '/home/pi/bin/'

        com = switch command
            when 'bright' then 'led-bright'
            when 'dim'    then 'led-dim'
            else 'led ' + command
        
        exec root + com, connection
            .pipe(process.stdout)
    
    exec: ->

        @device = @getValue 'home_device'
        @action = @getValue 'home_action'

        @[@device] @action

module.exports = HomeModule