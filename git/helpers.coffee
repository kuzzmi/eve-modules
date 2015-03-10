Path = require 'path'
Fs   = require 'fs'

file2json = (file, path = process.cwd()) ->
    full = Path.join path, file
    if Fs.existsSync(full)
        return JSON.parse(Fs.readFileSync full)
    
json2file = (file, data, path = process.cwd()) ->
    full = Path.join path, file
    Fs.writeFileSync full, JSON.stringify data, null, 4

exports.getDirs = (rootDir) ->
    files = fs.readdirSync(rootDir)
    dirs = []

    for file in files
        if file[0] != '.'
            filePath = "#{rootDir}/#{file}"
            stat = fs.statSync(filePath)

            if stat.isDirectory()
                dirs.push(file)

    return dirs