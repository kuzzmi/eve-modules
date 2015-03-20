{ Module } = require '../../eve'
colors     = require 'colors/safe'
moment     = require 'moment'
CronJob    = require('cron').CronJob

API        = require './api'
config     = require './config'
Task       = require './task'

class PlanningModule extends Module

    attach: ->

        job = new CronJob '00 45 17 * * 1-5', =>
            @setValue 'planning_action', 'count'
            @setValue    'planning_tag', 'shop'
            
            @exec()

        job.start()


    prepare: ->
        @action   = @getValue 'planning_action'
        @item     = @getValue 'agenda_entry'
        @priority = @getValue 'planning_priority', 1
        @tag      = @getValue 'planning_tag'

        @query = []

        if @ordinal
            @ordinal = @stimulus.entities.ordinal.map (item) ->
                item.value

        if @datetime
            type = switch @datetime.type
                when 'value'    then @datetime.grain
                when 'interval' then 'interval'
                
            @datetime = switch type
                when 'second', 'hour'
                    moment(@datetime.value).format 'YYYY-M-DDTHH:mm'
                when 'interval'
                    moment(@datetime.to.value).format 'YYYY-M-DDTHH:mm'
                when 'day'
                    moment(@datetime.value).format 'DD MM'
        else
            @datetime = 'today'

    exec: ->
        @prepare()

        promise = @login().then (token) => @[@action](token)

        return promise

    login: ->
        return API.login().then (user) -> user.api_token

    ### Refactor? ###
    report: ->
        @query.push @datetime
        @query.push 'overdue'
        @query.push '@' + @tag if @tag

        @Eve.logger.debug @query
        
        API.query @query
            .then (response) =>
                list   = [  ]
                tasks  = [  ]
                report = ['']

                response.map (item) -> 
                    tasks = tasks.concat item.data

                tasks = tasks.map (task) -> new Task(task)

                @Eve.logger.debug tasks

                if tasks.length is 0
                    API.getCat()
                        .then (cat) => 
                            @Eve.logger.debug "WHERE IS MY CAAAAT?"
                            @Eve.logger.debug cat

                            html = @compileHtml "#{__dirname}/templates/nothing.jade", { cat }
                            phrase = 'You have no tasks'

                            @response
                                .addText phrase
                                .addVoice phrase
                                .addHtml html
                                .send()
                        .catch (err) ->
                            console.log(err)


                else

                    memory = []
                    tasks.map (task) ->
                        report.push "    #{task.datetime} #{task.content}"
                        list.push task.content
                        memory.push {
                            id: task.id
                            content: task.content
                        }

                    html = @compileHtml __dirname + '/templates/list.jade', { list: tasks }
                    report.push colors.yellow('    Total: ' + colors.bold(tasks.length.toString()))

                    @response
                        .addText report.join '\r\n'
                        .addVoice 'Here is a list of your tasks'
                        .addNotification list
                        .addHtml html
                        .send()

                    @Eve.memory.set 'planning', memory
            .catch (err) -> console.log(err)

    done: (token) ->

        memory = @Eve.memory.get 'planning'

        items = 
            ids: []
            token: token

        for i in @ordinal
            if memory[i - 1]
                items.ids.push memory[i - 1].id

        API.completeItems items
            .then (response) =>
                @response
                    .addText 'Good job, sir'
                    .addVoice 'Good job, sir'
                    .send()

    remind: (token) ->
        capitalize = (string) ->
            string[0].toUpperCase() + string.slice(1)

        item = 
            content     : capitalize @item
            token       : token
            priority    : @priority
            date_string : @datetime

        if @tag
            item.labels = JSON.stringify [config.labels[@tag].id]

        API.addItem item
            .then (item) =>
                text = @pick [ 'tasks', 'added' ], [ item.content ]

                @response
                    .addText text
                    .addVoice text
                    .addNotification text
                    .send()


    count: ->
        @query.push @datetime
        @query.push 'overdue'
        @query.push '@' + @tag if @tag

        API.query @query
            .then (tasks) =>
                @Eve.logger.debug tasks

                items = []
                tasks.map (item) -> items = items.concat item.data

                list = items.map (task) -> new Task(task)
                    
                amount = list.length

                code = [ 'tasks', 'count' ]
                code.push if amount is 0 then 'none' else 'some'

                if @tag
                    phrase = @pick code, [ amount, @tag ]
                else 
                    phrase = @pick code, [ amount, 'all groups' ]

                html = @compileHtml __dirname + '/templates/list.jade', { list }

                @response
                    .addHtml html
                    .addText phrase
                    .addVoice phrase
                    .addNotification phrase
                    .send()

module.exports = PlanningModule