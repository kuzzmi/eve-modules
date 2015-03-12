omdb    = require 'omdb'
Q       = require 'q'
colors  = require 'colors'
pos     = require 'pos'
PlexAPI = require 'plex-api'

{ Module } = require '../../eve'

class MediaModule extends Module

    prepare: ->
        @action     = @getValue 'media_action'
        @item       = @getValue 'search_query'
        @type       = @getValue 'media_type'
        @properties = if @media_properties then @media_properties.map (prop) -> return prop.value

    findMovie: ->
        search = Q.nbind omdb.search

        search { s: @item, type: 'movie' }
            .then (movies) ->                
                return movies
            , (err) =>
                @Eve.logger.debug "Fallback due to:\r\n#{err}"
                movies = [{
                    title: 'The Matrix'
                }]
                return movies

    exec: ->

        @prepare()

        if not @metadata

            client = new PlexAPI '192.168.0.4'

            client.query "/search?local=1&query=#{encodeURIComponent(@item)}"
                .then (results) =>
                    movies = results.video
                    @Eve.logger.debug movies
                    console.log(require('util').inspect(movies, true, 10, true))
                    titles = movies.map (m) -> m.attributes.title

            # @findMovie()
            #     .then (movies) =>
            #         titles = movies.map (m) -> m.title

                    if titles.length > 1
                        phrase = "I've found several movies"
                        @response
                            .addText  "#{phrase}: \r\n#{titles.join '\r\n'}"
                            .addVoice "#{phrase}. Please select one"
                            .send()

                        @metadata = { movies }

                        @Eve.waitForAction @

                    if titles.length is 1
                        phrase = "Prepare to watch \"#{titles[0]}\""
                        @response
                            .addText  "#{phrase}"
                            .addVoice "#{phrase}"
                            .send()
                    
                    if titles.length is 0
                        phrase = "Sorry, I found nothing. Are you sure you've asked for a real movie?"
                        @response
                            .addText phrase
                            .addVoice phrase
                            .send()
            
        else
            movies      = @metadata.metadata.movies
            message     = @metadata.message                        
            words       = new pos.Lexer().lex message
            taggedWords = new pos.Tagger().tag words

            titles = movies.map (m) -> m.attributes.title

            @Eve.logger.debug titles

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
                for noun in nouns when nouns
                    if noun[0] is ordinal
                        found = ordinals.indexOf ordinal
                        break

            if found is -1 and numbers.length > 0
                found = parseInt(numbers[0][0]) - 1

            @Eve.logger.debug movies
            @Eve.logger.debug found

            if movies[found]
                phrase = "You've chosen: #{movies[found].attributes.title}"
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