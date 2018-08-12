# Bootstrap a simulated multi-region Kafka deployment backed by CockroachDB

## Prereqs

- Local K8s
- 16G RAM [min recommended]
- 4 cores [min recommended]

## Installation

```bash
sh install.sh
```

## Mac DNS Helper

To use DNS locally we need some foo to resolve *.dev.localhost names correctly. On a Mac the easiest way is with DNSmasq.

### Install DNSmasq

```bash
# Update your homebrew installation
brew up
# Install dnsmasq
brew install dnsmasq
```

Add a one-liner to configure resolution of *.dev.localhost to 127.0.0.1

```bash
echo 'address=/.dev.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
```

Add to startup + bring up the daemon

```bash
# start on boot
sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons

### start the daemon
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
```

Add to MacOS resolvers:

```bash
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/dev'
```

To make sure your local .dev.localhost resolver is always at the top of your nic's resolver list, do:

System Preferences > Network > Wi-Fi (or whatever you use) > Advanced... > DNS > add 127.0.0.1 to top of the list.

Test it works correctly:

```bash
> dig elephant.dev.localhost

; <<>> DiG 9.9.7-P3 <<>> blah.dev.localhost
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19704
;; flags: qr aa rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;blah.dev.localhost.		IN	A

;; ANSWER SECTION:
blah.dev.localhost.	0	IN	A	127.0.0.1
```