class Movie
    constructor: (params) ->
        if params.attributes
            { @year, @title } = params.attributes

            @file = params.media[0].part[0].attributes.file

        else 
            { @year, @title } = params

module.exports = Movie