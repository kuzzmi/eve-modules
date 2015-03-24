{ Module } = require '../../eve'

class ReferenceModule extends Module

    exec: ->
        now   = new Date()
        hours = now.getHours()
        
        timeOfDay = switch
            when 4  <= hours < 12 then 'morning'
            when 12 <= hours < 18 then 'afternoon'
            when 18 <= hours < 23 then 'evening'
            else 'night'

        if @reference_name_type
            karmaChange = switch @reference_name_type.value
                when 'gentle'    then 2
                when 'offensive' then -5
                when 'you'       then 0
                when 'name'      then 1
                else 0
        else 
            karmaChange = 0
        
        karma = @Eve.memory.get 'karma' || 0
        console.log karma
        karma += karmaChange
        console.log karma


        code = [ @reference_type.value ]
        args = [ 
            timeOfDay,
            [ 'sir', 'Igor' ] 
        ]

        phrase = @pick code, args

        if karma < 0 then phrase = "I'm too offended..."
        
        @response
            .addText phrase
            .addVoice phrase
            .send()

        karma = @Eve.memory.set 'karma', karma

module.exports = ReferenceModule