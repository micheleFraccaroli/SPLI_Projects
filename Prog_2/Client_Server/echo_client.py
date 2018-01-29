import socket
import sys
import threading

# TCP/IP socket
lock = threading.Lock()
def func(j):
	for res in socket.getaddrinfo("127.0.0.1", 8080, socket.AF_UNSPEC, socket.SOCK_STREAM):
		af, socktype, proto, canonname, sa = res
		try:
			s = socket.socket(af, socktype, proto)
		except socket.error as msg:
			s = None
			continue
		try:
			s.connect(sa)
			for i in range(10):
				data = "token"+str(j)
				s.send(bytes(data,'ascii'))
				lock.acquire()
				print("--> thread n "+str(j)+" has send: "+data)
				lock.release()
				retr = s.recv(5).decode('ascii')
				while(len(retr)<5):
					retr= retr+s.recv(5-len(retr)).decode('ascii')
				lock.acquire()
				response = "<-- thread n "+str(j)+" has recived: "+retr
				print(response)
				lock.release()
				#s.recv(100)
			s.close()
		
		except socket.error as msg:
			s.close()
			print("error")
			s = None
			continue
		break

for i in range(5):
	t = threading.Thread(target=func,args=(i,))
	t.start()
	#func()

