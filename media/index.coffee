omdb   = require 'omdb'
colors = require 'colors'
pos    = require 'pos'

{ Module } = require '../../eve'

class MediaModule extends Module

    prepare: ->
        @action     = @getValue 'media_action'
        @item       = @getValue 'search_query'
        @type       = @getValue 'media_type'
        @properties = if @media_properties then @media_properties.map (prop) -> return prop.value

    findMovie: ->
        movies = [{
            title: 'The Matrix'
        }, {
            title: 'The Matrix Reloaded'
        }, {
            title: 'The Matrix Revolutions'
        }]
        titles = movies.map (m) => m.title
        return titles

    exec: ->

        @prepare()

        if not @metadata
            titles = @findMovie()

            if titles.length > 1
                phrase = "I've found several movies"
                @response
                    .addText "#{phrase}: \r\n#{titles.join '\r\n'}"
                    .addVoice "#{phrase}. Please select one"
                    .send()

                @metadata = { titles }

                @Eve.waitForAction @
            
            if titles.length is 0
                phrase = "Sorry, I found nothing. Are you sure you've asked for a real movie?"
                @response
                    .addText phrase
                    .addVoice phrase
                    .send()

            
        else
            movies      = @metadata.metadata.titles
            message     = @metadata.message                        
            words       = new pos.Lexer().lex message
            taggedWords = new pos.Tagger().tag words

            ordinals = [
                "first"
                "second"
                "third"
                "fourth"
                "fifth"
            ]

            nouns   = taggedWords.filter (tw) -> tw[1] is 'NN'
            numbers = taggedWords.filter (tw) -> tw[1] is 'CD'

            found = -1;

            for ordinal in ordinals
                for noun in nouns
                    if noun[0] is ordinal
                        found = ordinals.indexOf ordinal
                        break

            if found is -1
                found = parseInt(numbers[0][0]) - 1

            if movies[found]
                phrase = "You've chosen: #{movies[found]}"
            else
                phrase = "You've made wrong selection"

            @response
                .addText phrase
                .addVoice phrase
                .send()

            # @Eve.logger.debug taggedWords

            # @response
            #     .addText "I remember about these movies: \r\n#{movies.join '\r\n'}"
            #     .send()

###

[ [ 'The'  , 'DT' ],
  [ 'first', 'NN' ],
  [ 'one'  , 'NN' ],
  [ 'is'   , 'VBZ' ],
  [ 'good' , 'JJ' ] ]

###

        # movie @item, (err, data) =>
        #     phrase = "I'm trying to #{@action} a #{@type}: \"#{data.Title}\""

        #     report = [ 
        #         "I've found this #{@type}:"
        #         "     Title:".yellow + " #{data.Title}"
        #         "      Year:".yellow + " #{data.Year}"
        #         "  Director:".yellow + " #{data.Director}"
        #         ].join '\r\n'

            
        #     ###
            
        #         Here I should start searching the movie in the local library
        #         and if wasn't found...
        #                                               You know what to do ;)

        #         May be we can try to create a separate module for downloading stuff?..
        #         Then it can be triggered somewhere else...

        #         Like: When #{MovieName} is release then remind me to download it
                    


        #         https://www.npmjs.com/package/tortuga
        #         Take a look at this

        #         for music: https://github.com/jamon/playmusic

        #     ###

            

module.exports = MediaModule