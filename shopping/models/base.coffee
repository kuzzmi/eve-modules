Q      = require 'q'
colors = require 'colors/safe'
ebay   = require 'ebay-api'

class BaseModel
    constructor: (obj) ->
        @id          = obj.itemId
        @title       = obj.title
        @category    = obj.primaryCategory.categoryName if obj.primaryCategory
        @condition   = obj.condition.conditionDisplayName if obj.condition
        @link        = obj.viewItemURL
        @image       = obj.galleryURL
        @listingType = obj.listingInfo.listingType if obj.listingInfo
        @parsed      = @parse obj.title
        
        @type        = 'Other'
        @price       = '$' + obj.sellingStatus.convertedCurrentPrice.USD

        switch @listingType
            when 'Auction'
                @type  = @listingType
                @price = '$' + obj.sellingStatus.convertedCurrentPrice.USD
            when 'AuctionWithBIN'
                @type     = 'Auction with Buy It Now'
                @price    = '$' + obj.sellingStatus.convertedCurrentPrice.USD
                @BINprice = '$' + obj.listingInfo.convertedBuyItNowPrice.USD
            when 'FixedPrice'
                @type  = 'Fixed price'
                @price = '$' + obj.sellingStatus.convertedCurrentPrice.USD
            when 'StoreInventory'
                @type  = 'Store inventory'
                @price = '$' + obj.sellingStatus.convertedCurrentPrice.USD
            else
                @type  = 'Other'
                @price = '$' + obj.sellingStatus.convertedCurrentPrice.USD

    parse: ->

    formatProperty: (key, value) ->
        prependWithSpaces = (string, total) ->
            if total - string.length + 1 < 0
                return
                
            spaces = new Array(total - string.length + 1)
                .join ' '
            spaces + string

        if value
            formatted = colors.yellow(prependWithSpaces(key, 10) + ': ') + value
        else
            formatted = colors.yellow(prependWithSpaces(key, 10))

    getShippingInfo: ->
        ebay.ebayApiGetRequest {
            'serviceName': 'Shopping',
            'opType': 'GetSingleItem',
            'appId': 'IgorKuzm-e6eb-4580-8a63-f7a888125783',

            params: {
                'ItemId': @id
            }
        }, (error, data) ->
            if error then throw error
            console.dir(data);
        console.log @id
        request = 
            serviceName : 'Shopping'
            opType      : 'GetShippingCosts'
            appId       : 'IgorKuzm-e6eb-4580-8a63-f7a888125783'
            params      : 
                ItemId: @id

        ebay.ebayApiGetRequest request, (err, data) ->
            console.log data

    summarize: (details) ->
        # deferred = Q.defer()

        report = ['']

        report.push @formatProperty 'Title', @title
        report.push @formatProperty 'Category', @category
        report.push @formatProperty 'Condition', @condition

        if details then report = report.concat details
        
        report.push @formatProperty '====='
        report.push @formatProperty 'Type', @type
        if @BINprice
            report.push @formatProperty 'Price', colors.green(@price)
            report.push @formatProperty 'Buy It Now', colors.yellow(@BINprice)
        else
            if @listingType is 'Auction'
                report.push @formatProperty 'Price', colors.green(@price)
            else
                report.push @formatProperty 'Price', colors.yellow(@price)
        report.push @formatProperty 'Link', @link

        report.push ''

        return report.join '\r\n'

        # deferred.promise

module.exports = BaseModel