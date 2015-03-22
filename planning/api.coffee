todoist = require 'node-todoist'
config  = require './config'
Q       = require 'q'
request = Q.nbind(require 'request')

exports.query = (query) ->
    deferred = Q.defer()

    convertedQuery = JSON.stringify(query)

    params = 
        queries: convertedQuery
    todoist.request 'query', params
        .then (result) -> deferred.resolve result

    deferred.promise

exports.getProjects = ->
    deferred = Q.defer()
    todoist.request 'getProjects'
        .then (result) -> deferred.resolve result
    deferred.promise

exports.getLabels = ->
    deferred = Q.defer()
    todoist.request 'getLabels'
        .then (result) -> deferred.resolve result
    deferred.promise

exports.login = ->
    deferred = Q.defer()

    credentials =
        email    : config.email
        password : config.password

    todoist.login credentials
        .then deferred.resolve

    deferred.promise

exports.addItem = (item) ->
    deferred = Q.defer()

    todoist.request 'addItem', item
        .then deferred.resolve

    deferred.promise

exports.completeItems = (items) ->
    deferred = Q.defer()

    items.ids = JSON.stringify(items.ids)

    todoist.request 'completeItems', items
        .then deferred.resolve

    deferred.promise


getUncompletedItems: (id) ->
    deferred = Q.defer()

    params =
        project_id: id || config.projects.PROJECTS

    todoist.request 'getUncompletedItems', params
        .then (response) -> deferred.resolve response

    deferred.promise

exports.getCat = () ->
    options = 
        url: 'https://montanaflynn-cat-overflow.p.mashape.com/?limit=100&offset=1'
        headers:
            "X-Mashape-Key": "f5pEC2LjcVmsh5BikAwnIQkLaXB4p1K17emjsnidQA6ubYNE5L"
            "Accept": "text/plain"
        # proxy: 'http://eu-chbs-proxy.eu.novartis.net:2010'

    request options
        .then (response) ->
            data = response[1].split('\n')
            rand = (min) -> Math.floor( Math.random() * min )

            r = rand(data.length - 1)
            data[r]
        , (err) -> return err
        .catch (err) -> return err
