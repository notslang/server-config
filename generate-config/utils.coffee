_ = require 'lodash'

# remove the mount path from the filename and set the filesystem name
extractFilesystemFromPath = (filesystems, path) ->
  for {name} in filesystems
    if path.startsWith('/' + name)
      return {
        filesystem: name
        path: path.replace('/' + name, '') # only does one replacement
      }

  return {filesystem: 'root', path} # no match

disableUnit = (config, unitName) ->
  config.systemd.units.push(name: unitName, mask: true)

addUnit = (config, {name, enable, contents, dropins}) ->
  unit = {name}
  if enable then unit.enabled = true
  if contents then unit.contents = contents + '\n'
  if dropins then unit.dropins = dropins
  config.systemd.units.push(unit)

addDirectory = (config, {path, mode, owner}) ->
  directory = extractFilesystemFromPath(config.storage.filesystems, path)
  [user, group] = owner.split(':')
  directory.user = {id: if user is 'core' then 500 else 0}
  directory.group = {id: if group is 'core' then 500 else 0}
  directory.mode = parseInt('' + mode, 8)
  config.storage.directories.push(directory)

addFile = (config, {path, mode, owner, contents}) ->
  file = extractFilesystemFromPath(config.storage.filesystems, path)
  file.contents = {
    source: "data:,#{encodeURIComponent(contents)}"
  }
  [user, group] = owner.split(':')
  file.user = {id: if user is 'core' then 500 else 0}
  file.group = {id: if group is 'core' then 500 else 0}
  file.mode = parseInt('' + mode, 8)
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

module.exports = {
  addDirectory,
  addFile,
  addFilesystem,
  addUnit,
  disableUnit,
  normalizeConfig
}
