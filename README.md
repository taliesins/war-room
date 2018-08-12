# War Room

Bootstrap a simulated multi-region Kafka and CockroachDB deployment.

## Hardware

- 16G RAM [min recommended]
- 4 cores [min recommended]

# OS specific configuration

- Local K8s installtion 

## Mac

### Certificate Pre-requisites
Use the built in openssl.

### DNS Pre-requisites
/etc/hosts
```
```

Another options would be to use dnsmasq

#### Install DNSmasq

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

### Build Pre-requisites
https://github.com/nodejs/node-gyp#on-macos


## Windows

### Certificate Pre-requisites

Download and install OpenSSL and put it on the path.

### DNS Pre-requisites

A number of dns entries need to be created in order to facilitate Traefik using host headers for routing.

C:\Windows\System32\drivers\etc\hosts
```
10.0.75.1 docker.dev.localhost nexus.dev.localhost
127.0.0.1 localhost dev.localhost traefik.dev.localhost k8s.dev.localhost alertmanager.dev.localhost prometheus.dev.localhost frontend.dev.localhost
```

Another option is to use something like Acrylic DNS Proxy
AcrylicHosts.txt:
```
10.0.75.1 docker.dev.localhost nexus.dev.localhost docker.dev.localhost.* nexus.dev.localhost.*
127.0.0.1 localhost *.localhost *.localhost.*
```

`10.0.75.1` is the default ip you get with Docker For Windows. This will allow containers to make use of servers outside of Kubernetes.

### Build Pre-requisites
https://github.com/nodejs/node-gyp#on-windows

## Installation

```bash
sh install.sh
```
