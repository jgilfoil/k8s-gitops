# Troubleshooting

# K3s

## k3s log location
```
less /var/log/k3s.log
less /var/log/syslog
journalctl -u k3s
```
## Embedded etcd3

See etcd tool and commands [here](https://gist.github.com/superseb/0c06164eef5a097c66e810fe91a9d408)