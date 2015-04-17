Home = require "../../home"

class Movie
    constructor: (@title, @year, @file, @poster, @rating) ->

    # This method will pass @file to VLC media player through Home.exec
    play: ->

        Home.exec
            home_device: "music"
            home_action: "pause"

        Home.exec
            home_device: "theater"
            home_action: "on"

        seconds = 15

        setTimeout () ->
            Home.exec
                home_device: "vlc"
                home_params: movie.file 
                home_action: "play"
        , seconds * 1000

    pause: ->

        Home.exec
            home_device: "vlc"
            home_action: "pause"

module.exports = Movie
