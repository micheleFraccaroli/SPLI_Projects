% test client

t = tcpip('192.168.43.69', 8081, 'NetworkRole', 'client');
fopen(t);
data = '123';
fwrite(t, data);