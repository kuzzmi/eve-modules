{ Module } = require 'eve'
Home       = require '../home'
Weather    = require '../weather'
Planning   = require '../planning'
# External   = require 'eve-module-git'

class StatusModule extends Module
    
    exec: ->
        action = @status_action.value
        type   = @status_type.value
        value  = @status_value.value

        date = new Date()
        hours = date.getHours()
        timeOfDay = switch
            when 4  <= hours < 12 then 'morning'
            when 12 <= hours < 18 then 'afternoon'
            when 18 <= hours < 23 then 'evening'
            else 'night'
        
        code = [ action, type, value ]
        args = [  'sir',  timeOfDay  ]

        phrase = @pick code, args

        @response
            .addText phrase
            .addVoice phrase
        
        if action is 'update' and type is 'awake' and value is 'true'
            @response
                .addResponse Weather.exec()
                .send()
        
        if action is 'update' and type is 'athome' and value is 'true'
            tasksAtHome = Planning.exec 
                planning_action : 'count'
                planning_tag    : 'home'
                
            @response
                .addResponse tasksAtHome
                .send()

        Home.exec
            home_device : 'led'
            home_action : 'power'

module.exports = StatusModule