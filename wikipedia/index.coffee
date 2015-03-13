Q           = require 'q'
WikiScraper = require 'wikiscraper'
colors      = require 'colors'
request     = Q.denodeify(require 'request')

{ Module } = require '../../eve'

class WikiModule extends Module
    reportFromJson: (properName, description, data) ->
        reportData = data.infobox.fields;

        prependWithSpaces = (string, total) ->
            if total - string.length + 1 < 0
                return ''
            spaces = new Array(total - string.length + 1)
                .join ' '
            spaces + string

        longest = 0

        for k, v of reportData
            if longest < k.length
                longest = k.length

        strings = ['']
        strings.push prependWithSpaces(      'Title', longest).yellow + ': ' + (properName + '').yellow.bold
        strings.push prependWithSpaces('Description', longest).yellow + ': ' + description
        strings.push '';

        for k, v of reportData
            if not k or not v 
                continue

            desc = prependWithSpaces k.replace(/\n/g, ''), longest
            strings.push (desc + ': ').yellow + 
                (v.replace /\n\nList\n\n/g, ''
                    .replace /\n/g, '; '
                    .replace /^; /g, ''
                    .replace /(; ){2,}/g, '')

        strings.join '\n'

    exec: ->
        @query  = @getValue 'wikipedia_search_query'
        @action = @getValue 'wikipedia_action'

        @Eve.logger.debug @query

        url = 'http://en.wikipedia.org/w/api.php'
        qs  =
            action    : 'opensearch'
            search    : @query
            limit     : 1
            namespace : 0
            format    : 'json'

        request { url, qs }
            .then (res) =>
                data = JSON.parse res[1]

                if data[2].length is 0 
                    response = "Sorry, I've found nothing about #{@query}"
                    return @response
                        .addText response
                        .addVoice response
                        .send()

                properName = data[1]

                description = data[2][0]

                wikiscraper = new WikiScraper [properName]
                
                wikiscraper.scrape (err, element) =>

                    if err then @Eve.logger.error err.stack

                    report = @reportFromJson properName, description, element
                    if description
                        phrase = description.replace /(\s*\([^)]*\))/g, ''
                    else
                        phrase = "Sorry, I've found nothing about #{@query}"

                    @response
                        .addText report
                        .addVoice phrase
                        .send()

            .catch (err) =>
                @Eve.logger.error err.stack

module.exports = WikiModule