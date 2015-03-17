Twitter = require './wrapper'
{ Module } = require '../../eve'

class TwitterModule extends Module

    attach: ->

        #Twitter.stream 'statuses/filter', { track: '#eve' }
        #    .then (stream) =>

        #        stream.on 'data', (tweet) =>
        #            console.log tweet.text
        #            # @Eve.logger.debug tweet
        #            # @response.addText(tweet.text).send()
        #    .catch (err) -> @Eve.logger.error err.stack

module.exports = TwitterModule