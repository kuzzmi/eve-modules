git        = require 'git-promise'
gitUtils   = require 'git-promise/util'
versiony   = require 'versiony'

Home       = require '../home'

{ Module, Config } = require '../../eve'

class GitModule extends Module
    
    push: (repo) ->
        cwd = Config.git.repos[repo]
        
        versiony
            .from 'package.json'
            .patch()
            .to 'package.json'
        
        git 'add -A', { cwd }
            .then -> git 'commit -m "[Eve] Uploaded at ' + new Date() + '"', { cwd }
            .then -> git 'push origin master', { cwd }
            .then => 
                info = versiony.end()
                phrase = 'Uploaded v' + info.version

                @response
                    .addText phrase
                    .addVoice phrase
                    .addNotification phrase
                    .send()

    pull: (repo) ->
        cwd = Config.git.repos[repo]

        git 'pull origin master', { cwd }
            .then (output) =>
                pkg = require './package.json'
                phrase = 'Updated to v' + pkg.version
                
                @response
                    .addText phrase
                    .addVoice phrase
                    .addNotification phrase
                    .send()

                return response

    status: (repo) ->
        cwd = Config.git.repos[repo]

        git 'status --porcelain', { cwd }
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
        @[@git_action.value](@git_repo.value)

module.exports = GitModule