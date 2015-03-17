omdb    = require 'omdb'
Q       = require 'q'
colors  = require 'colors'
pos     = require 'pos'
PlexAPI = require 'plex-api'

Home    = require '../home'

Movie = require './models/movie'

{ Module } = require '../../eve'

class MediaModule extends Module

    prepare: ->
        @action     = @getValue 'media_action'
        @item       = @getValue 'search_query'
        @type       = @getValue 'media_type'
        @properties = if @media_properties then @media_properties.map (prop) -> return prop.value

    findMovieOMDB: ->
        search = Q.nbind omdb.get

        search { title: @item, type: 'movie' }
            .then (movies) =>
                @Eve.logger.debug movies
                
                movies
            , (err) =>
                @Eve.logger.debug "Fallback due to:\r\n#{err}"
                # movies = [{
                #     title: 'The Matrix'
                # }]
                movies = []
                movies

    findMoviePlex: ->
        client = new PlexAPI '192.168.0.4'

        client.query "/search?local=1&query=#{encodeURIComponent(@item)}"
            .then (results) =>
                movies = results.video
                movies

    findMovie: ->
        # @findMovieOMDB()
        @findMoviePlex()
            .then(
                (movies) => if not movies then return @findMovieOMDB() else return movies, 
                (error) => return @findMovieOMDB()
            )
            .then (movies) =>

                if movies instanceof Array
                    movies
                        .map (m) -> new Movie(m)                    
                        .sort (m1, m2) -> +m1.year - +m2.year
                else if movies?
                    @Eve.logger.debug movies
                    [ new Movie movies ]
                else 
                    []

            .then (movies) =>

                if movies.length > 1
                    phrase = "I've found several movies"

                    report = [ "     Year  Title".yellow.bold ]
                    notification = []

                    for movie, index in movies
                        { year, title } = movie
                        report.push "  #{index + 1}  #{year}  #{title}"
                        notification.push "#{year} #{title}"

                    @response
                        .addText  "#{phrase}: \r\n#{report.join '\r\n'}"
                        .addVoice "#{phrase}. Please select one"
                        .addNotification notification
                        .send()

                    @metadata = { movies }

                    @Eve.waitForAction @

                if movies.length is 1
                    @turnOn movies[0]

                if movies.length is 0
                    phrase = "Sorry, I found nothing. Are you sure you've asked for a real movie?"
                    @response
                        .addText phrase
                        .addVoice phrase
                        .send()
            .catch (err) =>
                @Eve.logger.error err.stack

    turnOn: (movie) ->

        phrase = "Prepare to watch \"#{movie.title}\""
        
        home = Home.exec
            home_device: "theater"
            home_action: "on"

        seconds = 15
        setTimeout () ->
            Home.exec
                home_device: "vlc"
                home_action: movie.file
        , seconds * 1000

        @response
            .addText  "#{phrase}"
            .addVoice "#{phrase}"
            .addResponse home
            .send()

    exec: ->

        @prepare()

        if not @metadata
            switch @action
                when 'turn on'
                    @findMovie().then (movie) =>
                        if movie and movie instanceof Movie then @turnOn movie
            
        else
            movies      = @metadata.metadata.movies
            message     = @metadata.message
            words       = new pos.Lexer().lex message
            taggedWords = new pos.Tagger().tag words

            # titles = movies.map (m) -> m.attributes.title

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

            if movies[found]
                movie = movies[found]
                @turnOn movie
                # phrase = "You've chosen: #{movie.title}"
            else
                phrase = "You've made wrong selection"

            # @response
            #     .addText phrase
            #     .addVoice phrase
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

            
        ####
        #https://www.npmjs.com/package/node-rtorrent
        #    Here I should start searching the movie in the local library
        #    and if wasn't found...
        #                                          You know what to do ;)
        #    May be we can try to create a separate module for downloading stuff?..
        #    Then it can be triggered somewhere else...
        #    Like: When #{MovieName} is release then remind me to download it
        #    https://www.npmjs.com/package/tortuga
        #    Take a look at this
        #    for music: https://github.com/jamon/playmusic
        #    
        ####

            

module.exports = MediaModule