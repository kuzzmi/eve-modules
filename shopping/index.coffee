colors     = require 'colors'
ebay       = require 'ebay-api'
Q          = require 'q'
Categories = require './categories.json'

{ Module, Config } = require '../../eve'

class ShoppingModule extends Module

    exec: ->

        @query = @getValue 'search_query'

        params =
            keywords        : [ @query            ]
            outputSelector  : [ 'AspectHistogram' ]
            # sortOrder       : [ 'PricePlusShippingLowest' ]
            
            'paginationInput.entriesPerPage' : 5

        filters =
            itemFilter   : [ new ebay.ItemFilter 'AvailableTo', 'CH'          ]
            domainFilter : [ new ebay.ItemFilter 'domainName' , 'Electronics' ]

        ### DON'T FORGET TO PLACE IT TO CONFIG AND OMIT ###
        request = 
            serviceName : 'FindingService'
            opType      : 'findItemsByKeywords'
            appId       : Config.ebay.appId
            params      : params
            filters     : filters
            parser      : ebay.parseItemsFromResponse

        getItems = Q.nbind ebay.ebayApiGetRequest
        getItems request
            .then (items) =>
                phrase = "I've found some good deals about #{@query}"

                @response
                    .addVoice phrase

                report = phrase + '\r\n'

                models = items.map (item) ->
                    modelName = Categories[item.primaryCategory.categoryName]
                    try
                        Model = require './models/' + modelName
                    catch e
                        Model = require './models/base'
                    
                    model = new Model item
                    return model

                summarizing = []

                for model in models
                    summarizing.push(
                        model.summarize()
                            .then (summary) =>
                                report += summary
                    )

                html = @compileHtml "#{__dirname}/templates/list.jade", { items: models }
                
                @response
                    .addHtml html
                    .send()

                # Q.all(summarizing).then => 
                #     @response
                #         .addText report
                #         .send()

            .catch (err) =>
                @Eve.logger.error err.stack

module.exports = ShoppingModule