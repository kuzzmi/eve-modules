git        = require 'git-promise'
gitUtils   = require 'git-promise/util'
versiony   = require 'versiony'

Home       = require '../home'

{ Module } = require '../../eve'

class GitModule extends Module
    
    push: ->
        versiony
            .from 'package.json'
            .patch()
            .to 'package.json'
        
        git 'add -A'
            .then -> git 'commit -m "[Eve] Uploaded at ' + new Date() + '"'
            .then -> git 'push origin master'
            .then => 
                info = versiony.end()
                phrase = 'Uploaded v' + info.version

                @response
                    .addText phrase
                    .addVoice phrase
                    .addNotification phrase
                    .send()

    pull: ->
        git 'pull origin master'
            .then (output) =>
                pkg = require './package.json'
                phrase = 'Updated to v' + pkg.version
                
                @response
                    .addText phrase
                    .addVoice phrase
                    .addNotification phrase
                    .send()

                return response

    status: ->
        git 'status --porcelain'
            .then (output) =>
                tree = gitUtils.extractStatus(output).workingTree

                modified = tree.modified.length
                added    = tree.added.length
                deleted  = tree.deleted.length
                renamed  = tree.renamed.length
                copied   = tree.copied.length

                report   = ''

                formatChange = (change, text) ->
                    if change is 0 then return                    
                    report += text + ' ' + change + ' file'
                    if change > 1 then report += 's'
                    report += '. '

                formatChange modified, 'Modified'
                formatChange    added, 'Added'
                formatChange  deleted, 'Deleted'
                formatChange  renamed, 'Renamed'
                formatChange   copied, 'Copied'

                if report.length is 0
                    report = 'Everything is up-to-date, sir'

                @response
                    .addText report
                    .addVoice report
                    .addNotification report
                    .send()
    
    exec: ->

        switch @git_action.value
            when 'status' then @status()
            when 'pull'   then   @pull()
            when 'push'   then   @push()

module.exports = GitModule