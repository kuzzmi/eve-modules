Path = require 'path'

module.exports = (Eve) ->

    reloadModule = (msg) ->
        moduleName = msg.match[1]
        module = Path.join(Eve.modulesPath, moduleName)
        delete require.cache[require.resolve(module)]
        try
            Eve.registerModule Eve.modulesPath, moduleName
            msg.send "Module #{moduleName} reloaded"
        catch e
            Eve.logger.error "Couldn't reload #{moduleName}: \r\n #{e.stack}"

    Eve.respond /reload module (\w+)$/, reloadModule
    Eve.respond /reload (\w+) module$/, reloadModule

    Eve.respond /reload all modules/, (msg) ->
        for module of require.cache
            if module.indexOf Eve.modulesPath > -1
                delete require.cache[require.resolve(module)]
                
        try
            Eve.register Eve.modulesPath
            msg.send "Modules reloaded"
        catch e
            Eve.logger.error "Couldn't reload modules: \r\n #{e.stack}"