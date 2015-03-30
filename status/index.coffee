{ Module } = require '../../eve'
Home       = require '../home'
Weather    = require '../weather'
Planning   = require '../planning'

class StatusModule extends Module
    
    doAtHome: (device, action) ->
        Home.exec
            home_device : device
            home_action : action            

    turnOffEverything: ->
        @doAtHome 'projector_screen', 'up'
        @doAtHome        'projector', 'off'
        @doAtHome          'monitor', 'off'
        @doAtHome            'music', 'pause'        
        @doAtHome              'led', 'off'
                
    usualResume: ->
        @doAtHome 'monitor', 'on'
        @doAtHome     'led', 'on'
        @doAtHome   'music', 'play'

    exec: ->
        action = @status_action.value
        type   = @status_type.value
        value  = @status_value.value

        status = @Eve.memory.get 'status'

        if not status
            status = {
                athome : false,
                awake  : true
            }

        status[type] = eval(value)

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
        
        if action is 'update' 
            if type is 'awake' 

                if value is 'true'
                    @usualResume()
                    # @response
                    #     .addResponse Weather.exec()
                    #     
                else if value is 'false'                   
                    @turnOffEverything()

            if type is 'athome'
                if value is 'false'
                    @turnOffEverything()

                else if value is 'true'
                    tasksAtHome = Planning.exec 
                        planning_action : 'count'
                        planning_tag    : 'home'

                    @usualResume()

                    @response
                        .addResponse tasksAtHome

        @Eve.memory.set 'status', status

        @response
            .addText phrase
            .addVoice phrase
            .send()

module.exports = StatusModule