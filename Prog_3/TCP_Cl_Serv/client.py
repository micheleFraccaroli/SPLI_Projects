import socket
import os
import time

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
downloadDir = "/home/michele/Scrivania/SPLI_Project/Prog_3/TCP_Cl_Serv/tmp/"

info = tcp_info()
pinfo = pointer(info)
len_info = c_uint32(sizeof(tcp_info))
plen_info = pointer(len_info)

f_out = open('stat_client.out', 'wt')
for res in socket.getaddrinfo(HOST, PORT, socket.AF_UNSPEC, socket.SOCK_STREAM):
    af, socktype, proto, canonname, sa = res
    try:
        s = socket.socket(af, socktype, proto)
    except socket.error as msg:
        s = None
        continue
    try:
        s.connect(sa)
        print('Connected')
        filename = input('Enter your filename: ')
        name_len = len(filename)
        s.send(bytes(str(name_len), 'ascii'))
        ack = s.recv(3).decode('ascii')
        print('Ricevuti ' + str(len(ack)) + ' byte (ACK)')
        s.send(bytes(filename, 'ascii'))
        with open(filename, 'wb') as file_to_write:
            print('File aperto')
            time_start = time.time()
            while True:
                data = s.recv(1024)
                res = libc.getsockopt(s.fileno(), socket.SOL_TCP, socket.TCP_INFO, pinfo, plen_info)
                current_time = time.time()
                if res == 0:
                    for n in (x[0] for x in tcp_info._fields_):
                        if (n == 'tcpi_snd_cwnd'):
                            stat_time = current_time - time_start
                            # print('time: '+str(stat_time)+ ' ' + n,getattr(info,n))
                            f_out.write(str(stat_time) + ' ' + str(getattr(info, n)) + '\n')
                print('Ricevuti ' + str(len(data)) + ' byte')
                if not data:
                    print('Finito')
                    break
                file_to_write.write(data)
            time_finish = time.time()
            stat = os.stat(filename)
            vel = round((stat.st_size / (time_finish - time_start)) / 1024, 2)
            print('Velocità media: ' + str(vel) + ' KB/s')
            file_to_write.close()
            f_out.close()
        s.close()

    except socket.error as msg:
        s.close()
        print("error")
        s = None
        continue
    break
