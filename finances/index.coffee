{ Module, Config } = require '../../eve'
CronJob    = require('cron').CronJob

class FinancesModule extends Module

    attach: ->
        new CronJob '00 30 13 * * 1-5', =>
            reminder = "Don't forget to enter your lunch expenses"

            @response
                .addText reminder
                .addVoice reminder
                .send()
        , null, true

module.exports = FinancesModule