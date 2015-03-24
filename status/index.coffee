{ Module } = require '../../eve'
Home       = require '../home'
Weather    = require '../weather'
Planning   = require '../planning'

class StatusModule extends Module
    
    doAtHome: (device, action) ->
        Home.exec
            home_device : device
            home_action : action            

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
        
        if action is 'update' and type is 'awake' and value is 'true'
            @doAtHome 'monitor', 'on'
            @doAtHome     'led', 'on'
            @doAtHome   'music', 'play'

            @response
                .addResponse Weather.exec()

        if action is 'update' and type is 'awake' and value is 'false'
            @doAtHome 'projector_screen', 'up'
            @doAtHome        'projector', 'off'
            @doAtHome          'monitor', 'off'
            @doAtHome            'music', 'pause'        
            @doAtHome              'led', 'off'

        if action is 'update' and type is 'athome' and value is 'false'
            @doAtHome   'led', 'off'
            @doAtHome 'music', 'pause'

        if action is 'update' and type is 'athome' and value is 'true'
            tasksAtHome = Planning.exec 
                planning_action : 'count'
                planning_tag    : 'home'

            @doAtHome   'led', 'on'
            @doAtHome 'music', 'play'                
            @response
                .addResponse tasksAtHome

        @response
            .addText phrase
            .addVoice phrase
            .send()

module.exports = StatusModule