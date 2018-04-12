fs = require 'fs'

{addFile} = require './utils'
{HOSTNAME_TO_IP, HOSTNAME_TO_TINC_IP, hasPublicIp, isVps} = require './nodes'

addTinc = (config, nodeHostname) ->
  tincIp = HOSTNAME_TO_TINC_IP[nodeHostname]
  addFile(
    config
    path: '/data/tinc/tinc-up'
    mode: 755
    owner: 'core:core'
    contents: """
    #!/bin/sh
    # This file sets up the tap device.
    # It gives you the freedom to do anything you want with it.
    # Use the correct name for the tap device:
    # The environment variable $INTERFACE is set to the right name
    # on most platforms, but if it doesn't work try to set it manually.

    # Give it the right ip and netmask. Remember, the subnet of the
    # tap device must be larger than that of the individual Subnets
    # as defined in the host configuration file!
    ifconfig $INTERFACE #{tincIp} netmask 255.255.255.0

    """
  )
  addFile(
    config
    path: '/data/tinc/tinc-down'
    mode: 755
    owner: 'core:core'
    contents: '''
    #!/bin/sh
    # This file closes down the tap device.

    ifconfig $INTERFACE down

    '''
  )
  addFile(
    config
    path: '/data/tinc/rsa_key.priv'
    mode: 600
    owner: 'root:root'
    contents: fs.readFileSync("./tinc-keys/#{nodeHostname}.priv", 'utf8')
  )

  tincConfig = """
  Name = #{nodeHostname}
  Device = /dev/net/tun

  """

  for hostname in Object.keys(HOSTNAME_TO_TINC_IP)
    addPeer(config, nodeHostname, hostname)

    console.warn hostname, hasPublicIp(hostname)
    if hasPublicIp(hostname)
      tincConfig += "ConnectTo = #{hostname}\n"

  addFile(
    config
    path: '/data/tinc/tinc.conf'
    mode: 644
    owner: 'core:core'
    contents: tincConfig
  )

addPeer = (config, nodeHostname, hostname) ->
  hostConfig = "Subnet = #{HOSTNAME_TO_TINC_IP[hostname]}/32\n\n" +
               fs.readFileSync("./tinc-keys/#{hostname}.pub")

  # all the non-VPS nodes can connect to each-other directly, with their homelab
  # network IP address, even though they don't have a public IP address
  if hasPublicIp(hostname) or not isVps(nodeHostname)
    hostConfig = """
    Address = #{HOSTNAME_TO_IP[hostname]}
    Port = 655

    """ + hostConfig

  addFile(
    config
    path: "/data/tinc/hosts/#{hostname}"
    mode: 644
    owner: 'core:core'
    contents: hostConfig
  )

module.exports = {addTinc}
