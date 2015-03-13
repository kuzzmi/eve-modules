Q = require 'q'
colors = require 'colors'

{ Module, Config } = require '../eve'

googleTranslate = require('google-translate')(Config.google.translateKey)

class TranslateModule extends Module

    getLanguageCode: (lang) ->
        langs = {
            afrikaans   : 'af',
            albanian    : 'sq',
            arabic      : 'ar',
            azerbaijani : 'az',
            basque      : 'eu',
            bengali     : 'bn',
            belarusian  : 'be',
            bulgarian   : 'bg',
            catalan     : 'ca',
            croatian    : 'hr',
            czech       : 'cs',
            danish      : 'da',
            dutch       : 'nl',
            english     : 'en',
            esperanto   : 'eo',
            estonian    : 'et',
            filipino    : 'tl',
            finnish     : 'fi',
            french      : 'fr',
            galician    : 'gl',
            georgian    : 'ka',
            german      : 'de',
            greek       : 'el',
            gujarati    : 'gu',
            hebrew      : 'iw',
            hindi       : 'hi',
            hungarian   : 'hu',
            icelandic   : 'is',
            indonesian  : 'id',
            irish       : 'ga',
            italian     : 'it',
            japanese    : 'ja',
            kannada     : 'kn',
            korean      : 'ko',
            latin       : 'la',
            latvian     : 'lv',
            lithuanian  : 'lt',
            macedonian  : 'mk',
            malay       : 'ms',
            maltese     : 'mt',
            norwegian   : 'no',
            persian     : 'fa',
            polish      : 'pl',
            portuguese  : 'pt',
            romanian    : 'ro',
            russian     : 'ru',
            serbian     : 'sr',
            slovak      : 'sk',
            slovenian   : 'sl',
            spanish     : 'es',
            swahili     : 'sw',
            swedish     : 'sv',
            tamil       : 'ta',
            telugu      : 'te',
            thai        : 'th',
            turkish     : 'tr',
            ukrainian   : 'uk',
            urdu        : 'ur',
            vietnamese  : 'vi',
            welsh       : 'cy',
            yiddish     : 'yi'
        }
        langs[lang]

    translate: ->
        @Eve.logger.debug @from

        translate = Q.nbind googleTranslate.translate
        translate(@phrase, @from, @to)
            .then (translation) =>
                text = '\n' +
                    ' [' + @from.yellow.bold + '] ' + translation.originalText + '\n' +
                    ' [' + @to.yellow.bold + '] ' + translation.translatedText

                voice = {
                    phrase: translation.translatedText,
                    lang: @to
                }

                @response
                    .addText text
                    .addVoice translation.translatedText
                    .send()

            .catch (err) => 
                if err.stack
                    @Eve.logger.error err.stack
                else 
                    @Eve.logger.error err

    detect: ->
        detect = Q.nbind googleTranslate.detectLanguage
        detect(@phrase).then (detection) =>
            @from = detection.language
            @Eve.logger.debug @from

    exec: ->
        @phrase = @getValue 'phrase_to_translate'
        @from   = @getLanguageCode(@getValue 'from')
        @to     = @getLanguageCode(@getValue   'to', 'english')

        deferred = Q.defer()

        if not @from
            @detect().then => @translate()
        else
            @translate()
            

module.exports = TranslateModule