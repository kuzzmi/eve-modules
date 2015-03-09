{ Module } = require 'eve'

Q          = require 'q'
Request    = require 'request'
Forecast   = require './forecast'

class Weather extends Module

    forecast: ->
        deferred = Q.defer()

        if @datetime.type is 'value' 
            type = @datetime.grain
        if @datetime.type is 'interval' 
            type = 'interval'

        url = 'http://api.openweathermap.org/data/2.5/'
        params =
            q     : @location
            units : 'metric'
            cnt   : '7'

        switch type
            when 'second' then url += 'weather'
            when 'hour', 'interval' then url += 'forecast'
            when 'day' then url += 'forecast/daily'

        Request
            url : url
            qs  : params
        , (err, resp, data) =>

            try
                data = JSON.parse resp.body
            catch e
                errorCallback e
            

            switch type
                when 'second'
                    weather = new Forecast data, type

                when 'day'
                    today = new Date();

                    day = new Date @datetime.value
                    diff = new Date(day - today)

                    daysFromNow = diff / 1000 / 60 / 60 // 24

                    weather = data.list.map((item) ->
                        item.city = data.city;
                        item;
                    )[daysFromNow + 1];

                    weather = new Forecast weather, type;

                when 'hour'
                    ut = new Date @datetime.value 
                        .getTime() // 1000

                    weather = data.list.filter((item) ->
                        item.dt <= ut && ut - item.dt < 10800;
                    )[0]

                    weather = new Forecast weather, 'second';
                
                when 'interval'
                    interval = {
                        from: new Date @datetime.from.value 
                            .getTime() // 1000,                            
                        to: new Date @datetime.to.value 
                            .getTime() // 1000
                    }

                    weather = data.list.filter((item) ->
                        item.dt > interval.from && item.dt < interval.to;
                    )[0]

                    weather = new Forecast weather, 'second';

            deferred.resolve weather.toString
                details: @details
                verbosity: @verbosity

        deferred.promise

    exec: ->

        @details   = if @details   then   @details.value else 'all' 
        @location  = if @location  then  @location.value else 'Basel' 
        @verbosity = if @verbosity then @verbosity.value else null
        
        @datetime ?= 
            type  : 'value'
            grain : 'second'
            value : new Date()

        @forecast()
            .then (result) =>
                { text, voice } = result
                
                phrase = @pick voice.code, voice.args

                @response
                    .addText text
                    .addVoice phrase
                    .addNotification text
                    .send()
        
module.exports = Weather