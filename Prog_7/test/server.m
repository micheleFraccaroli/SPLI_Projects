%test server

t = tcpip('192.168.43.69', 8081, 'NetworkRole', 'server');
fopen(t);
n_chunk_rcv = fread(t, 1, 'uint32');
fprintf(n_chunk_rcv);
