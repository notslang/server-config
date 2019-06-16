{ArgumentParser} = require 'argparse'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

packageInfo = require './package'

argparser = new ArgumentParser(
  addHelp: true
  description: 'Extract files from an ignition config'
  version: packageInfo.version
)

argparser.addArgument(
  ['directory']
  help: 'The DIRECTORY to unpack into.'
  type: 'string'
  metavar: 'DIRECTORY'
)

argv = argparser.parseArgs()

process.stdin.setEncoding 'utf8'
process.stdin.on 'readable', ->
  buffer = ''
  while (chunk = process.stdin.read()) isnt null
    buffer += chunk
  if buffer isnt ''
    unpackConfig(JSON.parse(buffer))
  return

unpackConfig = (config) ->
  for file in config.storage.files
    filePath = file.path
    if file.filesystem isnt 'root'
      filePath = path.join(file.filesystem, filePath)
    filePath = path.join(argv.directory, filePath)
    mkdirp.sync(path.dirname(filePath))
    fs.writeFileSync(
      filePath
      decodeURIComponent(file.contents.source[6...])
      encoding: 'utf8'
      mode: file.mode
    )
    fs.chownSync(filePath, file.user.id, file.group.id)
