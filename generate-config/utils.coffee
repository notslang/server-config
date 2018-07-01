_ = require 'lodash'

disableUnit = (config, unitName) ->
  config.systemd.units.push(name: unitName, mask: true)

addUnit = (config, {name, enable, contents, dropins}) ->
  unit = {name}
  if enable then unit.enable = true
  if contents then unit.contents = contents + '\n'
  if dropins then unit.dropins = dropins
  config.systemd.units.push(unit)

addFile = (config, {path, mode, owner, contents}) ->
  filesystem = 'root'
  for fsConfig in config.storage.filesystems
    # remove the mount path from the filename and set the filesystem name
    {name} = fsConfig
    if path.startsWith('/' + name)
      filesystem = name
      path = path.replace('/' + name, '') # only does one replacement
      break

  file = {
    filesystem
    path
    contents:
      inline: contents
  }
  [user, group] = owner.split(':')
  user = if user is 'core' then 500 else 0
  group = if group is 'core' then 500 else 0
  if user then file.user = {id: user}
  if group then file.group = {id: group}
  if mode then file.mode = parseInt('' + mode, 8)
  config.storage.files.push(file)


addFilesystem = (config, name, format, wipeFilesystem) ->
  # we setup btrfs volumes with the btrfs filesystem label tool, but the ext4
  # is setup with a label in parted.
  identifier = if format is 'btrfs' then 'by-label' else 'by-partlabel'
  config.storage ?= {}
  config.storage.filesystems ?= []
  config.storage.filesystems.push(
    {
      name: name
      mount:
        device: "/dev/disk/#{identifier}/#{name.toUpperCase()}"
        format: format
        wipeFilesystem: wipeFilesystem
    }
  )
  addUnit(
    config
    name: "#{name}.mount"
    enable: true
    contents: """
      [Mount]
      What=/dev/disk/#{identifier}/#{name.toUpperCase()}
      Where=/#{name}
      Type=#{format}

      [Install]
      WantedBy=local-fs.target
    """
  )

normalizeConfig = (config) =>
  config.storage.files = _.sortBy(config.storage.files , ['filesystem', 'path'])
  config.storage.filesystems = _.sortBy(config.storage.filesystems , ['name'])
  config.systemd.units = _.sortBy(config.systemd.units , ['name'])
  config.networkd.units = _.sortBy(config.networkd.units , ['name'])

module.exports = {disableUnit, addUnit, addFile, addFilesystem, normalizeConfig}
