{ArgumentParser} = require 'argparse'
fs = require 'fs'

packageInfo = require '../package'

argparser = new ArgumentParser(
  addHelp: true
  description: 'Make an Ignition profile file'
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

getCoreOsVersion = ->
  # find max version that we've downloaded. right now we don't care about the
  # channel, only the version number.
  fs.readdirSync('./matchbox/assets/coreos').reduce((versionA, versionB) ->
    [majorA, minorA, patchA] = versionA.split '.'
    [majorB, minorB, patchB] = versionB.split '.'
    if majorA < majorB
      return versionB
    else if majorA > majorB
      return versionA

    if minorA < minorB
      return versionB
    else if minorA > minorB
      return versionA

    if patchA < patchB
      return versionB
    else if patchA > patchB
      return versionA
    else
      throw new Error("versionA #{versionA} is the same as versionB #{versionB}")
  )

MATCHBOX_SERVER = 'http://192.168.1.70:8080'
COREOS_VERSION = getCoreOsVersion()

process.stdout.write JSON.stringify({
  id: argv.hostname,
  name: "CoreOS Container Linux - #{argv.hostname}",
  boot: {
    kernel: "/assets/coreos/#{COREOS_VERSION}/coreos_production_pxe.vmlinuz",
    initrd: ["/assets/coreos/#{COREOS_VERSION}/coreos_production_pxe_image.cpio.gz"],
    args: [
      'initrd=coreos_production_pxe_image.cpio.gz',
      "coreos.config.url=#{MATCHBOX_SERVER}/ignition?uuid=${uuid}&mac=${mac:hexhyp}",
      'coreos.first_boot=yes',
      'console=tty0',
      'console=ttyS0',
      'coreos.autologin'
    ]
  },
  ignition_id: "#{argv.hostname}.json"
}, null, 2) + '\n'
