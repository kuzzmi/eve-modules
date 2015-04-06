git             = require 'git-promise'
gitUtils        = require 'git-promise/util'
UpstreamChecker = require 'git-upstream-watch'
versiony        = require 'versiony'
CronJob         = require('cron').CronJob

Home            = require '../home'

{ Module, Config } = require '../../eve'

class GitModule extends Module

    attach: ->
        new CronJob '00 30 17,8 * * 1-5', =>
            reminder = "Don't forget to upload me"

            @response
                .addText reminder
                .addVoice reminder
                .send()
        , null, true

        mins = 5

        cb = ->

        for k, v of Config.git.repos
            checker = new UpstreamChecker v

            checker.check cb
            setInterval ->
                checker.check cb
            , mins * 60 * 1000
            checker.on 'divergence', (data) =>
                longMessage = "Detected divergence on #{k} repo of #{data.commits.length} commits between local and upstream branch"
                shortMessage = "\"#{k}\" is #{data.commits.length} commits behind remote"
                voice = "Repository #{k} is outdated"
                @Eve.logger.debug longMessage
                @response 
                    .addText longMessage
                    .addVoice voice
                    .addNotification shortMessage
                    .send()
    
    push: (repo) ->
        cwd = Config.git.repos[repo]
        
        git 'add -A', { cwd }
            .then -> git 'commit -m "[Eve] Uploaded at ' + new Date() + '"', { cwd }
            .then -> git 'push origin master', { cwd }
            .then => 
                phrase = "Uploaded #{repo}"

                # .addNotification phrase
                @response
                    .addText phrase
                    .addVoice phrase
                    .send()

    pull: (repo) ->
        cwd = Config.git.repos[repo]

        git 'pull origin master', { cwd }
            .then (output) =>
                pkg = require './package.json'
                phrase = 'Updated to v' + pkg.version
                
                # .addNotification phrase
                @response
                    .addText phrase
                    .addVoice phrase
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

                # .addNotification report
                @response
                    .addText report
                    .addVoice report
                    .send()
    
    exec: ->
        @[@git_action.value](@git_repo.value)

module.exports = GitModule
