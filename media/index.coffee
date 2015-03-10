movie = require 'node-movie'
colors = require 'colors'

{ Module } = require '../../eve'

class MediaModule extends Module

    prepare: ->
        @action     = @getValue 'media_action'
        @item       = @getValue 'search_query'
        @type       = @getValue 'media_type'
        @properties = if @media_properties then @media_properties.map (prop) -> return prop.value

    exec: ->

        @prepare()

        movie @item, (err, data) =>
            phrase = "I'm trying to #{@action} a #{@type}: \"#{data.Title}\""

            report = [ 
                "I've found this #{@type}:"
                "     Title:".yellow + " #{data.Title}"
                "      Year:".yellow + " #{data.Year}"
                "  Director:".yellow + " #{data.Director}"
                ].join '\r\n'

            ###
            
                Here I should start searching the movie in the local library
                and if wasn't found...
                                                      You know what to do ;)

                May be we can try to create a separate module for downloading stuff?..
                Then it can be triggered somewhere else...

                https://www.npmjs.com/package/tortuga
                Take a look at this

                for music: https://github.com/jamon/playmusic

            ###

            @response
                .addText report
                .addVoice phrase
                .send()

module.exports = MediaModule