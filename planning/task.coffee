moment = require 'moment'

class Task
    constructor: (task) ->
        {
            @priority
            @item_order
            @content
            @id
        } = task

        duedate = moment new Date(task.due_date)

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
          "item_order": 2,
          "content": "Fluffy ferret",
          "indent": 1,
          "project_id": 22073,
          "id": 210873,
          "checked": 1,
          "date_string": ""

        ###
    
module.exports = Task