{ArgumentParser} = require 'argparse'

packageInfo = require '../package'

{HOSTNAME_TO_MAC_ADDRESS} = require './nodes'

argparser = new ArgumentParser(
  addHelp: true
  description: 'Make an Ignition group file'
  version: packageInfo.version
)

argparser.addArgument(
  ['hostname']
  nargs: '?'
  defaultValue: 'coreos0'
  help: 'The HOSTNAME to generate a config for.'
  type: 'string'
  metavar: 'HOSTNAME'
)

argv = argparser.parseArgs()

# to keep it simple, I have 1 profile and 1 group and 1 ignition config for each
# node.

process.stdout.write JSON.stringify({
  id: argv.hostname,
  name: 'Simple CoreOS Container Linux',
  profile: argv.hostname,
  selector: {
    mac: HOSTNAME_TO_MAC_ADDRESS[argv.hostname]
  },
  metadata: {}
}, null, 2) + '\n'
