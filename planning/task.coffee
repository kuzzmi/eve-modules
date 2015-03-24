moment = require 'moment'
config = require './config'
colors = require 'colors/safe'

class Task
    constructor: (task) ->
        {
            @priority
            @item_order
            @content
            @id
            @due_date
            @date_string
            @indent
        } = task

        @label_names = []

        for id in task.labels
            for k, v of config.labels
                if v.id is id
                    @label_names.push v.name

        duedate = moment new Date(@due_date)

        if !!~(task.date_string.indexOf '@') || !!~(task.date_string.indexOf 'at')  
            @datetime = duedate.format 'MM/DD h:mm a'  
        else
            @datetime = duedate.format 'MM/DD'

        @isOverdue = duedate < new Date()
        ###
        
            "due_date": null,
            "user_id": 1,
            "collapsed": 0,
            "in_history": 1,
            "priority": 1,
            "labels": []
            "item_order": 2,
            "content": "Fluffy ferret",
            "indent": 1,
            "project_id": 22073,
            "id": 210873,
            "checked": 1,
            "date_string": ""

        ###
    
    textReport: ->
        string = "    "
        if @isOverdue
            string += "#{colors.bold.red(@datetime)}"
        else
            string += "#{colors.bold.green(@datetime)}"
        
        indent = new Array(@indent + 1).join('  ')
        
        string += "#{indent}#{@content}"

        for label in @label_names
            string += colors.green " @#{label}"
        
        string

module.exports = Task