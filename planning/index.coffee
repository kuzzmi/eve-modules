{ Module } = require '../../eve'
colors     = require 'colors'
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

        @Eve.logger.debug {
            @action  
            @item    
            @priority
            @tag     
        }

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
                report = ['']

                response.map (item) -> tasks = tasks.concat item.data

                if tasks.length is 0
                    phrase = 'You have no tasks'

                    @response
                        .addText phrase
                        .addVoice phrase
                        .send()

                else
                    tasks.map (task) ->
                        taskString = ''

                        if task.due_date
                            duedate = moment new Date(task.due_date)

                            if task.has_notification
                                taskString += duedate.format 'MM/DD h:mm a' + ' '
                            else
                                taskString += duedate.format 'MM/DD' + ' '
                            
                            if duedate < new Date()
                                taskString = taskString.red
                            else
                                taskString = taskString.green

                        taskString += task.content

                        report.push '    ' + taskString
                        list.push task.content

                    report.push '    Total: '.yellow + tasks.length.toString().yellow.bold

                    @response
                        .addText report.join '\r\n'
                        .addVoice 'Here is a list of your tasks'
                        .addNotification list
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

                amount = tasks.reduce(
                    (a, b) -> a + b.data.length, 
                    0
                )

                code = [ 'tasks', 'count' ]
                code.push if amount is 0 then 'none' else 'some'

                phrase = @pick code, [ amount, @tag ]

                @response
                    .addText phrase
                    .addVoice phrase
                    .addNotification phrase
                    .send()

module.exports = PlanningModule