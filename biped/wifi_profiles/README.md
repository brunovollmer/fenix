# How to setup wifi profile(s)

Create one or more files names like this format: `$SSID.nmconnection`

```yml
[connection]
id=$SSID
type=wifi
interface-name=wlan0

[wifi]
mode=infrastructure
ssid=$SSID

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=$PASSWORD

[ipv4]
method=auto

[ipv6]
addr-gen-mode=stable-privacy
method=auto

[proxy]
```

Replace `$SSID` and `$PASSWORD` with the appropriate variables
