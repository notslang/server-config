HOSTNAME_TO_IP =
  coreos0: '192.168.1.103'
  coreos1: '192.168.1.101'
  coreos3: '192.168.1.202'
  coreos4: '192.168.1.133'
  coreos5: '198.211.110.94'
  coreos6: '138.68.55.209'
  coreos7: '159.89.92.57'
  coreos8: '107.170.207.106'

HOSTNAME_TO_MAC_ADDRESS =
  coreos0: '00:25:90:10:e6:81'
  coreos1: 'e8:39:35:51:55:46'

# TODO: this will break with coreos10
HOSTNAME_TO_TINC_IP = {}
for hostname of HOSTNAME_TO_IP
  lastOctet = hostname[-1..]
  if lastOctet is '0' then lastOctet = '100'
  HOSTNAME_TO_TINC_IP[hostname] = "10.0.0.#{lastOctet}"

hasPublicIp = (hostname) ->
  not /192\.168\.1\./.test HOSTNAME_TO_IP[hostname]

isVps = hasPublicIp

getSwapSize = (hostname) ->
  if isVps(hostname)
    2
  else if hostname is 'coreos1'
    10
  else
    30

module.exports = {
  getSwapSize
  hasPublicIp
  isVps
  HOSTNAME_TO_IP
  HOSTNAME_TO_MAC_ADDRESS
  HOSTNAME_TO_TINC_IP
}
