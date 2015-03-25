Q       = require 'q'
request = Q.nbind(require 'request')

class BigOven
    constructor: (@apiKey) ->

    getRecipe: (id) ->
        options = 
            url: "http://api.bigoven.com/recipe/#{id}"
            qs: 
                api_key: @apiKey
            headers:
                Accept: "application/json"

        request options
            .then (response) ->
                data = JSON.parse response[1]
                
                ingridients = []

                for ingridient in data.Ingredients
                    ingridients.push ingridient.Name

                return ingridients
        
    search: (query) ->
        console.log query

        options = 
            url: "http://api.bigoven.com/recipes"
            qs: 
                title_kw: query
                pg: 1
                rpp: 1
                api_key: @apiKey
                sort: "quality"
            headers:
                Accept: "application/json"

        request options
            .then (response) ->
                data = JSON.parse response[1]

                data.Results[0].RecipeID
            .then (id) =>
                return @getRecipe id
    
module.exports = BigOven