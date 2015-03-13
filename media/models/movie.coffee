class Movie
    constructor: (params) ->
        if params.attributes
            { @year, @title } = params.attributes
        else 
            { @year, @title } = params

module.exports = Movie