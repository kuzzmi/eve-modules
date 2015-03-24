{ Module, Config } = require '../../eve'
colors     = require 'colors/safe'
moment     = require 'moment'
Q          = require 'q'
CronJob    = require('cron').CronJob

API        = require './api'
config     = require './config'
Task       = require './task'
BigOven    = require './bigoven'

class PlanningModule extends Module

    attach: ->

        job = new CronJob '00 45 17 * * 1-5', =>
            @setValue 'planning_action', 'count'
            @setValue    'planning_tag', 'buy_list'
            
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
                when 'day'            
                    @dateToString @datetime.value, 'DD MM YYYY'
                when 'interval'       
                    @dateToString @datetime.to.value, 'YYYY-M-DDTHH:mm'
                when 'second', 'hour', 'minute'
                    @dateToString @datetime.value, 'YYYY-M-DDTHH:mm'
        else
            @datetime = 'today'

        @Eve.logger.debug @datetime

    dateToString: (date, format) ->
        moment(date).format format

    stringToDate: (string) ->
        moment new Date string

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

                response.map (item) -> tasks = tasks.concat item.data

                tasks = tasks.map (task) -> new Task(task)

                if tasks.length is 0
                    API.getCat(Config.catoverflow)
                        .then (cat) => 
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
                    memory = tasks
                    tasks.map (task) ->
                        report.push task.textReport()
                        list.push task.content

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
                memory = memory.slice(0, i - 1).concat(memory.slice(i))

        API.completeItems items
            .then (response) =>

                @Eve.memory.set 'planning', memory

                @response
                    .addText 'Good job, sir'
                    .addVoice 'Good job, sir'
                    .send()

    postpone: (token) ->
        memory = @Eve.memory.get 'planning'

        tasks = []
        queue = []

        if @ordinal
            for i in @ordinal
                if memory[i - 1]
                    tasks.push memory[i - 1]
        else
            tasks = memory

        for task in tasks            
            task.due_date = moment(new Date(task.due_date)).add(1, 'day')
            if !!~(task.date_string.indexOf '@') || !!~(task.date_string.indexOf 'at')
                task.date_string = @dateToString task.due_date, 'YYYY-M-DDTHH:mm'
            else
                task.date_string = @dateToString task.due_date, 'MM/DD/YYYY'
            task.token = token
            queue.push(
                API.updateItem task
                    .then (item) =>
                        @response
                            .addText "#{item.content} is postponed"
            )

        Q.all queue
            .then =>
                @response
                    .addVoice 'Done, sir'
                    .send()
        
    remind: (token) ->
        capitalize = (string) ->
            string[0].toUpperCase() + string.slice(1)

        item = 
            content     : capitalize @item
            token       : token
            priority    : @priority
            date_string : @datetime

        @Eve.logger.debug item

        if @tag
            item.labels = JSON.stringify [config.labels[@tag].id]

        if @tag is 'cook'
            queue   = []
            ids     = []

            bigoven = new BigOven Config.bigoven.apiKey

            bigoven.search @item.replace /^cook /, ''
                .then (ingredients) =>
                    console.log ingredients
                    API.addItem item
                        .then (item) =>
                            @Eve.logger.debug item

                            text = @pick [ 'tasks', 'added' ], [ item.content ]

                            for ingredient in ingredients
                                buyTask = 
                                    content     : "Buy #{ingredient} @buy_list"
                                    token       : token
                                    indent      : 2
                                    priority    : @priority
                                    date_string : @datetime

                                API.addItem buyTask
                                    .then (task) -> 
                                        ids.push task.id
                                        console.log task.content

                            @response
                                .addText text
                                .addVoice text
                                .addNotification text
                                .send()
                .catch (err) ->
                    console.log err

        # 'http://api.bigoven.com/recipes?title_kw=oysters&pg=1&rpp=20&api_key='
        else
            API.addItem item
                .then (item) =>
                    @Eve.logger.debug item

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