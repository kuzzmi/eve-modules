{ Module } = require '../../eve'
colors     = require 'colors/safe'
moment     = require 'moment'
CronJob    = require('cron').CronJob

API        = require './api'
config     = require './config'

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
        
        API.query @query
            .then (response) =>
                list   = [  ]
                tasks  = [  ]
                items  = [  ]
                report = ['']

                response.map (item) -> tasks = tasks.concat item.data

                if tasks.length is 0
                    phrase = 'You have no tasks'

                    @response
                        .addText phrase
                        .addVoice phrase
                        .send()

                else
                    memory = []
                    tasks.map (task) ->
                        item = {}                        
                        { id, content } = task
                        item.content = content
                        _task = { id, content }
                        memory.push _task
                        taskString = ''

                        if task.due_date
                            duedate = moment new Date(task.due_date)

                            if task.has_notification || !!~(task.date_string.indexOf '@')
                                taskString += duedate.format 'MM/DD h:mm a' + ' '
                                item.datetime = duedate.format 'MM/DD h:mm a' + ' '
                            else
                                taskString += duedate.format 'MM/DD' + ' '
                                item.datetime = duedate.format 'MM/DD' + ' '
                            
                            if duedate < new Date()
                                item.isOverdue = true
                                taskString = colors.red(taskString)
                            else
                                item.isOverdue = false
                                taskString = colors.green(taskString)

                        taskString += task.content

                        report.push '    ' + taskString
                        list.push task.content
                        items.push item

                    html = @compileHtml __dirname + '/templates/list.jade', { list: items }
                    report.push colors.yellow('    Total: ' + colors.bold(tasks.length.toString()))

                    @response
                        .addText report.join '\r\n'
                        .addVoice 'Here is a list of your tasks'
                        .addNotification list
                        .addHtml html
                        .send()

                    @Eve.memory.set 'planning', memory

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
                    .addResponse PlanningModule.exec({planning_action: 'report'})
                    .send()

    remind: (token) ->
        item = 
            content     : @item
            token       : token
            priority    : @priority
            date_string : @datetime

        if @tag
            item.labels = JSON.stringify [config.labels[@tag].id]

        @Eve.logger.debug "Adding new task #{item}"

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

                list = items.map (task) =>
                    item = {}

                    if task.due_date
                        duedate = moment new Date(task.due_date)

                        if task.has_notification || !!~(task.date_string.indexOf '@')
                            item.datetime = duedate.format 'MM/DD h:mm a' + ' '
                        else
                            item.datetime = duedate.format 'MM/DD' + ' '

                        if duedate < new Date()
                            item.isOverdue = true
                        else
                            item.isOverdue = false
                    else
                        item.datetime = null

                    item.content = task.content

                    return item

                amount = tasks.reduce(
                    (a, b) -> a + b.data.length, 
                    0
                )

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