modprobe tcp_probe port=5001
chmod 444 /proc/net/tcpprobe
cat /proc/net/tcpprobe >/tmp/data_tcp_probe.out & TCPCAT=$!