{ Module, Config } = require '../../eve'
inspect = require('util').inspect
Imap = require 'imap'

class EmailModule extends Module

    attach: ->
        imap = new Imap
            user: Config.gmail.email,
            password: Config.gmail.password,
            host: 'imap.gmail.com',
            port: 993,
            tls: true

        openInbox = (cb) ->
            imap.openBox('INBOX', true, cb)

        imap.once 'ready', () ->
          openInbox (err, box) ->
            if err
                throw err
            f = imap.seq.fetch '1:3',
              bodies: 'HEADER.FIELDS (FROM TO SUBJECT DATE)'
              struct: true
            f.on 'message', (msg, seqno) ->
              console.log 'Message #%d', seqno
              prefix = '(#' + seqno + ') ';
              msg.on 'body', (stream, info) ->
                buffer = '';
                stream.on 'data', (chunk) ->
                  buffer += chunk.toString('utf8');
                stream.once 'end', () ->
                  console.log(prefix + 'Parsed header: %s', inspect(Imap.parseHeader(buffer)));
              msg.once 'attributes', (attrs) ->
                console.log(prefix + 'Attributes: %s', inspect(attrs, false, 8));
              msg.once 'end', () ->
                console.log(prefix + 'Finished');
            f.once 'error', (err) ->
              console.log('Fetch error: ' + err);
            f.once 'end', () ->
              console.log('Done fetching all messages!');
              imap.end();
        
         
        imap.once 'error', (err) ->
          console.log(err);
             
        imap.once 'end', () ->
          console.log('Connection ended');
         
        imap.connect();

        #Twitter.stream 'statuses/filter', { track: '#eve' }
        #    .then (stream) =>

        #        stream.on 'data', (tweet) =>
        #            console.log tweet.text
        #            # @Eve.logger.debug tweet
        #            # @response.addText(tweet.text).send()
        #    .catch (err) -> @Eve.logger.error err.stack

module.exports = EmailModule