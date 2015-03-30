{ Module, Config } = require '../../eve'
colors     = require 'colors/safe'
moment     = require 'moment'
Q          = require 'q'

API        = require './api'
config     = require './config'
Task       = require './task'
BigOven    = require './bigoven'

class PlanningModule extends Module

    attach: ->
        status = @Eve.memory.get 'status'

        @startJob '00 45 17 * * 1-5', =>
            if not status.athome
                @setValue 'planning_action', 'count'
                @setValue    'planning_tag', 'buy_list'
                @exec()

        @startJob '00 20 12 * * 1-5', =>
            if not status.athome
                reminder = "Don't miss a lunch! Enjoy your meal, sir."
                @response
                    .addText reminder
                    .addVoice reminder
                    .addNotification reminder
                    .send()

    prepare: ->
        @action     = @getValue 'planning_action'
        @item       = @getValue 'agenda_entry'
        @priority   = @getValue 'planning_priority', 1
        @tag        = @getValue 'planning_tag'
        @recurring  = @getValue 'planning_recurring'
        @datestring = @getValue 'planning_datestring'
        
        if @duration
            @duration = @duration.normalized.value 
        else
            # one hour is default
            @duration = 1 * 60 * 60

        @query = []

        if @ordinal
            @ordinal = @stimulus.entities.ordinal.map (item) ->
                item.value

        if @datetime
            @date_type = switch @datetime.type
                when 'value'    then @datetime.grain
                when 'interval' then 'interval'
                
            @datetime = switch @date_type
                when 'day'            
                    @dateToString @datetime.value, 'YYYY-MM-DD'
                when 'interval'       
                    @dateToString @datetime.to.value, 'YYYY-M-DDTHH:mm'
                when 'second', 'hour', 'minute'
                    @dateToString @datetime.value, 'YYYY-M-DDTHH:mm'
        else
            @datetime = 'today'

        if @recurring 
            # Should transform { recurring_word + datetime + datetype } to 
            # a proper datestring like
            #       every Friday
            #       every weekend 

            # Let's store recurring word first
            tempDate = @recurring + " " 
            switch @date_type
                when 'day'
                    tempDate += @getDayFromDate @datetime
            @datetime = "#{tempDate}"
            
    secondsToMinutes: (seconds) ->
        ~~(seconds / 60)       

    getDayFromDate: (date) ->
        mom = if date is "today" then moment() else @stringToDate date

        mom.format('dddd')

    dateToString: (date, format) ->
        moment(date).format format

    stringToDate: (string) ->
        moment new Date string

    exec: ->
        @prepare()

        promise = @login()
            .then (token) => @[@action](token)
            .catch (err) => console.log err

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
                    duration = 0
                    tasks.map (task) ->
                        report.push task.textReport()
                        list.push task.content
                        if task.duration
                            duration += task.duration

                    html = @compileHtml __dirname + '/templates/list.jade', { list: tasks }

                    report.push "    Total: #{tasks.length.toString()} (#{duration} mins)"

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

        if @tag
            item.labels = JSON.stringify [config.labels[@tag].id]

        if @duration
            mins = @secondsToMinutes @duration
            item.content += " [#{mins} min]"

        if @tag is 'cook'
            queue   = []
            ids     = []

            bigoven = new BigOven Config.bigoven.apiKey

            bigoven.search @item.replace /^cook /, ''
                .then (ingredients) =>
                    console.log ingredients
                    API.addItem item
                        .then (item) =>

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