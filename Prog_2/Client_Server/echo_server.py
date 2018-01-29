#!/usr/bin/env python3

import sys
import socket
import threading
import time

lock = threading.Lock()

class Counter():
	def __init__(self):
		self.n=0
		self.lock = threading.Lock()
	def inc(self):
		self.lock.acquire()
		self.n+=1
		self.lock.release()
	def getN(self):
		self.lock.acquire()
		var = self.n
		self.lock.release()
		return(var)
soc = None
c =0
for res in socket.getaddrinfo("10.14.208.129", 8080, socket.AF_UNSPEC, socket.SOCK_STREAM,0,socket.AI_PASSIVE):
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




def t_fun(conn,addr):
	for i in range(10):
		retr = conn.recv(6).decode('ascii')
		while(len(retr) < 6):
			retr = retr+conn.recv(6-len(retr)).decode('ascii')
		lock.acquire()
		print("connected to client_thread n: "+retr[5:]+" recived "+retr[:5])
		lock.release()
		conn.send(bytes(retr[:5],'ascii'))
	conn.close()

while(True):
	conn,addr = s.accept()
	c=c+1
	lock.acquire()
	print("connessione n "+str(c))
	lock.release()
	sys.stdout.flush()
	t = threading.Thread(target=t_fun,args=(conn,addr))
	t.start()
	





