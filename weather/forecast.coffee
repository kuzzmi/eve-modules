class BaseForecast
    constructor: (params, type) ->
        
        SpecificForecast = require './forecasts/' + type + 'Forecast'

        @item = new SpecificForecast params

    toString: (params) ->
        result = @item.toString params
        
        {
            voice:
                code: result[0].code
                args: result[0].args
            text:
                result[1]
        }

module.exports = BaseForecast