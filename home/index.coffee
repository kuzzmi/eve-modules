exec = require 'ssh-exec'

{ Module } = require '../../eve'

raspberry = 
    user     : 'pi'
    host     : '192.168.0.9'
    password : 'raspberry'

class HomeModule extends Module

    led: (command) ->

        connection = exec.connection raspberry

        root = '/home/pi/bin/'

        com = switch command
            when 'bright' then 'led-bright'
            when 'dim'    then 'led-dim'
            else 'led ' + command
        
        exec root + com, connection
            .pipe(process.stdout)

    theater: (command) ->
        connection = exec.connection raspberry

        root = '/home/pi/bin/'

        com = "theater_#{command}"
        
        exec root + com, connection
            .pipe(process.stdout)
    
    exec: ->

        @device = @getValue 'home_device'
        @action = @getValue 'home_action'

        @[@device] @action

module.exports = HomeModule