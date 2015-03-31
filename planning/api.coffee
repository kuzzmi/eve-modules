todoist = require 'node-todoist'
config  = require './config'
Q       = require 'q'
request = Q.nbind(require 'request')

Task    = require './task'

exports.query = (query) ->
    deferred = Q.defer()

    convertedQuery = JSON.stringify(query)

    params =
        queries: convertedQuery
    todoist.request 'query', params
        .then (result) ->
            tasks = []
            response.map (item) -> tasks = tasks.concat item.data
            # Convert all items from tasks to Task
            tasks = tasks.map (task) -> new Task task

            deferred.resolve tasks

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

    if not item instanceof Task
        console.warn "Item is not an Item :("

    todoist.request 'addItem', item
        .then deferred.resolve

    deferred.promise

exports.updateItem = (item) ->
    deferred = Q.defer()

    todoist.request 'updateItem', item
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

exports.getCat = (config) ->
    _request = Q.nbind request

    _request params
        .then (response) ->
            data = JSON.parse response[1]

        , (err) ->
            console.log err.stack

        .catch (err) ->
            console.log err.stack

    request config
        .then (response) ->
            data = response[1].split('\n')
            rand = (min) -> Math.floor( Math.random() * min )

            r = rand(data.length - 1)
            data[r]
        , (err) -> return err
        .catch (err) -> return err
