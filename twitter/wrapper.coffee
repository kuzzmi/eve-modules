Q       = require 'q'
Twitter = require 'twitter'
{ Config } = require '../../eve'

client  = new Twitter
    consumer_key        : Config.twitter.consumer_key
    consumer_secret     : Config.twitter.consumer_secret
    access_token_key    : Config.twitter.access_token_key
    access_token_secret : Config.twitter.access_token_secret

exports.get = (endpoint, params) ->
    get = Q.nbind client.get, client

    return get endpoint, params
        .then (resp) ->
            {
                data   : resp[0],
                body   : resp[1]
            }
        .catch (err) ->
            console.log err.stack

exports.post = (endpoint, params) ->
    post = Q.nbind client.post, client

    return post endpoint, params
        .then (resp) ->
            {
                data   : resp[0],
                body   : resp[1]
            }
        .catch (err) ->
            console.log err.stack

###

client.stream('statuses/filter', {track: 'javascript'}, function(stream) {
  stream.on('data', function(tweet) {
    console.log(tweet.text);
  });
 
  stream.on('error', function(error) {
    throw error;
  });
});

###

exports.stream = (endpoint, params) ->
    stream = Q.nbind client.stream, client

    return stream endpoint, params
        .catch (stream) -> return stream