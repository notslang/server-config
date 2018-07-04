_ = require 'lodash'
fs = require 'fs'
{ArgumentParser} = require 'argparse'

packageInfo = require '../package'
{HOSTNAME_TO_IP, HOSTNAME_TO_TINC_IP, hasPublicIp, isVps, getSwapSize} = require './nodes'

{addTinc} = require './tinc'
{
  addDirectory
  addFile
  addFilesystem
  addUnit
  disableUnit
  normalizeConfig
} = require './utils'

MASTER_HOSTNAME = 'coreos0'
MASTER_IP = HOSTNAME_TO_IP[MASTER_HOSTNAME]

ETCD_ENDPOINTS = (
  "http://#{ip}:2379" for ip in Object.values(HOSTNAME_TO_IP)
).join(',')

argparser = new ArgumentParser(
  addHelp: true
  description: 'Make an ignition config file'
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

addAuthorizedKey = (config, {contents}) ->
  config.passwd.users[0]['ssh_authorized_keys'] ?= []
  config.passwd.users[0]['ssh_authorized_keys'].push(contents)

addSshKey = (config, {name, contents}) ->
  addFile(
    config,
    path: "/home/core/.ssh/#{name}"
    mode: 620
    owner: 'core:core'
    contents: contents
  )

addSwap = (config, size) ->
  if size is 0 then return
  addUnit(
    config
    name: 'swap.service'
    enable: true
    contents: """
    [Unit]
    Description=Turn on swap

    [Service]
    Type=oneshot
    Environment="SWAP_PATH=/ephemeral" "SWAP_FILE=swap"
    ExecStartPre=-/usr/bin/rm -rf ${SWAP_PATH}
    ExecStartPre=/usr/bin/mkdir -p ${SWAP_PATH}
    ExecStartPre=/usr/bin/touch ${SWAP_PATH}/${SWAP_FILE}
    ExecStartPre=/bin/bash -c "fallocate -l #{size}G ${SWAP_PATH}/${SWAP_FILE}"
    ExecStartPre=/usr/bin/chmod 600 ${SWAP_PATH}/${SWAP_FILE}
    ExecStartPre=/usr/sbin/mkswap ${SWAP_PATH}/${SWAP_FILE}
    ExecStartPre=/usr/sbin/sysctl vm.swappiness=10
    ExecStart=/sbin/swapon ${SWAP_PATH}/${SWAP_FILE}
    ExecStop=/sbin/swapoff ${SWAP_PATH}/${SWAP_FILE}
    ExecStopPost=-/usr/bin/rm -rf ${SWAP_PATH}
    RemainAfterExit=true

    [Install]
    WantedBy=multi-user.target
    """
  )

addBondInterface = (config) ->
  config.networkd =
    units: [
      {
        name: '00-eth.network',
        contents: '''
          [Match]
          Name=eth*

          [Network]
          Bond=bond0

          '''
      },
      {
        name: '10-bond0.netdev',
        contents: '''
          [NetDev]
          Name=bond0
          Kind=bond

        '''
      },
      {
        name: '20-bond0.network',
        contents: '''
          [Match]
          Name=bond0

          [Network]
          DHCP=true

        '''
      }
    ]

addNetworkConfig = (config, {ipAddr}) ->
  addFile(
    config
    path: '/etc/systemd/network/00-static.network'
    mode: 600
    owner: 'root:root'
    contents: """
    [Match]
    Name=bond0

    [Network]
    Address=#{ipAddr}/24
    Gateway=192.168.1.1

    """
  )

addSshConfig = (config, nodeHostname) ->
  for file in fs.readdirSync './ssh-keys'
    content = fs.readFileSync("./ssh-keys/#{file}", 'utf8')
    if /\.pub$/.test(file)
      addAuthorizedKey(config, contents: content)
    else
      addSshKey(config, name: file, contents: content)

  sshConfig = ''
  for hostname, ip of HOSTNAME_TO_IP
    if hostname is nodeHostname then continue # no need to reference localhost
    if hasPublicIp(nodeHostname) and not hasPublicIp(hostname)
      # make connection with tinc (we're assuming everything without a public IP
      # is on the same internal network)
      ip = HOSTNAME_TO_TINC_IP[hostname]
    sshConfig += """
    Host #{hostname}
        HostName #{ip}
        User core

    """

  addFile(
    config
    path: '/home/core/.ssh/config'
    mode: 600
    owner: 'core:core'
    contents: sshConfig
  )

ignitionConfig =
  ignition:
    version: '2.2.0'
  passwd:
    users: [
      {
        name: 'core'
      }
    ]
  storage:
    directories: []
    files: []
    filesystems: []
  systemd:
    units: []
  networkd:
    units: []

addUnit(
  ignitionConfig
  name: 'systemd-timesyncd.service'
  enable: true
)

# disable ntpd because we use timesyncd
disableUnit(ignitionConfig, 'ntpd.service')

ip = HOSTNAME_TO_IP[argv.hostname]

addSwap(ignitionConfig, getSwapSize(argv.hostname))

if not isVps(argv.hostname)
  # disable everything related to updates and update-related rebooting. we do
  # updates by rebooting the node with a new PXE image, not by installing an
  # update on each CoreOS node
  disableUnit(ignitionConfig, 'update-engine-stub.service')
  disableUnit(ignitionConfig, 'update-engine-stub.timer')
  disableUnit(ignitionConfig, 'update-engine.service')
  disableUnit(ignitionConfig, 'locksmithd.service')

  addBondInterface(ignitionConfig)
  addFilesystem(ignitionConfig, 'ephemeral', 'ext4', true)
  addFilesystem(ignitionConfig, 'data', 'btrfs', false)
  addUnit(
    ignitionConfig
    name: 'docker.service'
    enable: true
    dropins: [
      {
        name: '20-clct-docker.conf'
        contents: '''
        [Service]
        Environment="DOCKER_OPTS=-g=/data/docker"
        '''
      }
    ]
  )

addDirectory(
  ignitionConfig
  path: '/data'
  mode: 755
  owner: 'core:core'
)

addDirectory(
  ignitionConfig
  path: '/ephemeral'
  mode: 755
  owner: 'core:core'
)

addTinc(ignitionConfig, argv.hostname)
addSshConfig(ignitionConfig, argv.hostname)

addFile(
  ignitionConfig
  path: '/etc/hostname'
  mode: 644
  owner: 'root:root'
  contents: argv.hostname
)

for file in fs.readdirSync './bash-profile'
  addFile(
    ignitionConfig
    path: "/etc/profile.d/#{file}"
    mode: 755
    owner: 'root:root'
    contents: fs.readFileSync("./bash-profile/#{file}", 'utf8')
  )

addFile(
  ignitionConfig
  path: '/etc/ssh/sshd_config'
  mode: 600
  owner: 'root:root'
  contents: fs.readFileSync('./config/sshd_config', 'utf8')
)

if not isVps(argv.hostname)
  # manually set the host keys to prevent the SSH fingerprint from changing
  # between reboots. we could store this stuff in /data, but if there's an issue
  # with mounting /data, then I still want to be able to SSH into the system.
  for type in ['dsa', 'ecdsa', 'ed25519', 'rsa']
    privateKey = fs.readFileSync(
      "./ssh-host-keys/#{argv.hostname}/ssh_host_#{type}_key"
      'utf8'
    )
    addFile(
      ignitionConfig
      path: "/etc/ssh/ssh_host_#{type}_key"
      mode: 600
      owner: 'root:root'
      contents: privateKey
    )
    publicKey = fs.readFileSync(
      "./ssh-host-keys/#{argv.hostname}/ssh_host_#{type}_key.pub"
      'utf8'
    )
    addFile(
      ignitionConfig
      path: "/etc/ssh/ssh_host_#{type}_key.pub"
      mode: 644
      owner: 'root:root'
      contents: publicKey
    )

normalizeConfig(ignitionConfig)

process.stdout.write JSON.stringify(ignitionConfig, null, 2)
