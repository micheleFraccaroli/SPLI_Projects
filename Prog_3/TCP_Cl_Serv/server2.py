import socket
import struct
import time
import math
import os
from ctypes import *

cdll.LoadLibrary('libc.so.6')
libc = CDLL('libc.so.6')


class tcp_info(Structure):
    _fields_ = [
        ('tcpi_state', c_uint8),
        ('tcpi_ca_state', c_uint8),
        ('tcpi_retransmits', c_uint8),
        ('tcpi_probes', c_uint8),
        ('tcpi_backoff', c_uint8),
        ('tcpi_options', c_uint8),
        ('tcpi_snd_wscale', c_uint8, 4),
        ('tcpi_rcv_wscale', c_uint8, 4),
        ('tcpi_rto', c_uint32),
        ('tcpi_ato', c_uint32),
        ('tcpi_snd_mss', c_uint32),
        ('tcpi_rcv_mss', c_uint32),
        ('tcpi_unacked', c_uint32),
        ('tcpi_sacked', c_uint32),
        ('tcpi_lost', c_uint32),
        ('tcpi_retrans', c_uint32),
        ('tcpi_fackets', c_uint32),
        ('tcpi_last_data_sent', c_uint32),
        ('tcpi_last_ack_sent', c_uint32),
        ('tcpi_last_data_recv', c_uint32),
        ('tcpi_last_ack_recv', c_uint32),
        ('tcpi_pmtu', c_uint32),
        ('tcpi_rcv_ssthresh', c_uint32),
        ('tcpi_rtt', c_uint32),
        ('tcpi_rttvar', c_uint32),
        ('tcpi_snd_ssthresh', c_uint32),
        ('tcpi_snd_cwnd', c_uint32),
        ('tcpi_advmss', c_uint32),
        ('tcpi_reordering', c_uint32),
        ('tcpi_rcv_rtt', c_uint32),
        ('tcpi_rcv_space', c_uint32),
        ('tcpi_total_retrans', c_uint32)
    ]


HOST = "127.0.0.1"
PORT = 8084
chunk = 1024 * 1024
soc = None
c = 0
for res in socket.getaddrinfo(HOST, PORT, socket.AF_UNSPEC, socket.SOCK_STREAM, 0, socket.AI_PASSIVE):
    af, socktype, protocol, canonname, sa = res
    print(str(res))
    try:
        s = socket.socket(af, socktype, protocol)
    except socket.error as msg:
        s = None
        continue
    try:
        s.bind(sa)
        s.listen(10000)
    except socket.error as msg:
        s.close()
        print(str(msg))
        s = None
        continue
    break
if s is None:
    raise Exception('Socket start error')
else:
    soc = s
info = tcp_info()
pinfo = pointer(info)
len_info = c_uint32(sizeof(tcp_info))
plen_info = pointer(len_info)

time_start = time.time()
while (1):
    conn, addr = s.accept()
    print('Accept')
    name_len = int(conn.recv(1).decode('ascii'))
    print('Lunghezza nome file: ' + str(name_len))
    conn.send(bytes('ack', 'ascii'))

    reqFile = conn.recv(name_len).decode('ascii')
    while (len(reqFile) < name_len):
        reqFile = reqFile + conn.recv(name_len - len(reqFile)).decode('ascii')
    print('Nome file: ' + str(reqFile))

    file_size = os.path.getsize(reqFile)
    f = open(reqFile, 'rb')
    n_chunk = int(math.ceil(file_size / chunk))
    f_out = open('stat_server.out', 'wt')
    for k in range(int(file_size / chunk)):
        st = f.read(int(chunk))
        # conn.send(bytes(string_chunk(self.chunk, 5), 'ascii'))
        conn.send(st)
        res = libc.getsockopt(conn.fileno(), socket.SOL_TCP, socket.TCP_INFO, pinfo, plen_info)
        current_time = time.time()
        if res == 0:
            for n in (x[0] for x in tcp_info._fields_):
                if (n == 'tcpi_snd_cwnd'):
                    stat_time = current_time - time_start
                    print('time: ' + str(stat_time) + ' ' + n, getattr(info, n))
                    f_out.write(str(stat_time) + ' ' + str(getattr(info, n)) + '\n')
    r_chunk = int(file_size % chunk)
    if r_chunk > 0:
        # print(string_chunk(r_chunk, 5))
        st = f.read(int(r_chunk))
        # conn.send(bytes(string_chunk(r_chunk, 5), 'ascii'))
        conn.send(st)

    # with open(str(reqFile), 'rb') as file_to_send:
    #	print('File aperto')
    #	for data in file_to_send:

    #		conn.sendall(data)
    print('File mandato')
    f_out.close()
    f.close()

    conn.close()
socket.close()
