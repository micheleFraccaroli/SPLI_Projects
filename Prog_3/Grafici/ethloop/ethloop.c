/* vim: cin sw=4 ts=4
*/
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/poll.h>
#include <netpacket/packet.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/time.h>
#include <signal.h>

int sock;

int find_device(const char *name,char *hwaddr) /* rets -1 on error */
{
	struct ifreq ifr;
	ifr.ifr_ifindex = -1;
	strcpy(ifr.ifr_name,name);
	assert(ioctl(sock,SIOCGIFHWADDR,&ifr)!=-1);
	memcpy(hwaddr,ifr.ifr_hwaddr.sa_data,6);
	strcpy(ifr.ifr_name,name);
	assert(ioctl(sock,SIOCGIFINDEX,&ifr)!=-1);
	return ifr.ifr_ifindex;
}

/* packet send or recieved */
struct _xbuf {
	char dst[6],src[6];
	unsigned short proto; // 12
	unsigned short size;  // 14
	unsigned long time;   // 16
	unsigned long flowid; // 20
	unsigned long pktid;  // 24
	unsigned long k1;	  // 28 kernel info
	unsigned long k2;	  // 32 kernel info
	unsigned long k3;	  // 36 kernel info
	unsigned long k4;	  // 40 kernel info
   	char pad[1500];
} buf;

unsigned long us;	/* actual time updated by synctime */

#define FLOWS 20		/* max flows; see maxflow variable too */
#define SLOGSZ 1000		/* max log records */
#define PROGSZ 1000		/* max commands */
#define CMDSSZ 200		/* max string size of command */
#define MSTIME 100000	/* measure interval in us */
#define LOGTIME 500000	/* log interval in us */

/* in memory statictic results */
struct statlog {
	long av_rate[FLOWS],av_delay[FLOWS],av_jitter[FLOWS],av_wrate[FLOWS];
} slog[SLOGSZ],*stp;
int slog_cnt = 0;

/* controling program */
struct progdata {
	unsigned time;
	unsigned flow;
	long data;
	char code,str[CMDSSZ];
} prog[PROGSZ];
int progsize = 0,progcounter = 0;

/* table of flows */
struct flowtab {
	int rate;		/* transmit rate in Bps */
	int pktsize;	/* tx packet size */
	int jitter;		/* tx packet size jitter */
	int prio;
	int prio_rng;	/* no of prios to randomly generate from prio base */
	int tx_dev;		/* device no we send on */
	int rx_dev;		/* device no we recieve from */
	char smac[6];	/* source and target MACs to use */
	char tmac[6];
	
	long bytes;		/* byte counter of tx TBF */
	long rbytes;	/* total bytes resieved */
	long wbytes;	/* total bytes send */

	unsigned long cp;	/* checkpoint time of tx TBF */
	long av_rate;		/* avg of rx rate */
	long av_wrate;		/* avg of tx rate */
	long av_delay;		/* avg of pkt delay [us] */
	long av_jitter;		/* avg jitter of delay */

} ftab[FLOWS];
int maxflow = 0;	/* max flow no used till now */
	
/* send buf to flow */
int send_raw(int flow)
{
	struct flowtab *f = ftab+flow;
	int r,prio;
	struct sockaddr_ll addr = { AF_PACKET,0,f->tx_dev,0,0,6,};
	/*
	struct pollfd pf = {sock,POLLOUT,0};
	if(poll(&pf,1,0) <= 0) {
		fprintf(stderr,"*");
		return 0;
	}
	*/
	memcpy(addr.sll_addr,f->tmac,6);
	memcpy(buf.dst,addr.sll_addr,6);
	memcpy(buf.src,f->smac,6);
	/* set unused protocol for testing */
	buf.proto = addr.sll_protocol = htons(ETH_P_CUST);
	buf.flowid = flow; buf.time = us;
	buf.size = f->pktsize; 
	buf.k1=buf.k2=buf.k3=buf.k4=0;
	if (f->jitter) buf.size += rand()/(RAND_MAX/f->jitter);

	prio = f->prio;
	if (f->prio_rng) prio += rand()/(RAND_MAX/f->prio_rng);
	setsockopt(sock,SOL_SOCKET,SO_PRIORITY,&prio,4);
	r = sendto(sock,&buf,f->pktsize,MSG_DONTWAIT,(struct sockaddr*)&addr,sizeof(addr));
	if (r != f->pktsize) {
		if (r == -1 && errno == ENOBUFS) return 1;
		if (r == -1 && errno == EWOULDBLOCK) 
			fprintf(stderr,"*"); /* block; probably too big queues */
		else fprintf(stderr,"send returned %d errno=%d!\n",r,errno);
		return 0;
	}
	return 1;
}

/* try to get packet: wait tmo ms for it, returns 0 if timeout */
int recv_raw(int tmo)
{
	struct pollfd pf = {sock,POLLIN,0};
	int r; unsigned short proto;
	if(poll(&pf,1,tmo) <= 0) return 0;
	r = recv(sock,&buf,1550,0);
	if (r <= 0) {
		printf("error recv (%d)\n",r);
		return 0;
	}
	if (ntohs(buf.proto) != ETH_P_CUST) {
//		fprintf(stderr,"recv packet proto %X\n",(int)buf.proto);
		return 0;
	}
	return 1;
}

/* set us to time in us */
void synctime ()
{
	static struct timeval cp = { 0,0 };
	struct timeval tv;
	gettimeofday(&tv,0); if (!cp.tv_sec) cp = tv;
    tv.tv_sec -= cp.tv_sec; 
	us = tv.tv_sec * 1000000 + tv.tv_usec - cp.tv_usec;
}

/* computes ewma */
#define EWMAC 4
#define EWMA(V,X) (V) += (X) - (V)/EWMAC

/* ctrl-c handler */
volatile int sigint = 0;
void intsig(int sig)
{
	sigint = 1;
}

/* reads program from stdin into prog/progsize */
void readprog ()
{
	char buf[2*CMDSSZ],*s; int n;
	struct progdata *p = prog;
	while (fgets(buf,2*CMDSSZ,stdin)) {
		if (*buf == '#' || *buf<' ') continue;
		buf[2*CMDSSZ-1] = 0; s = buf + strlen(buf); 
		while (s > buf && *s <= 32) *s-- = 0;
		memset (p,0,sizeof(*p));
		if (sscanf (buf,"%u %c %u %n",&p->time,&p->code,&p->flow,&n) < 3) {
			fprintf (stderr,"bad line in program: %s\n",buf);
			exit (5);
		}
		memcpy (p->str,buf+n,CMDSSZ); p->str[CMDSSZ-1] = 0;
		p->data = strtol (buf+n,&s,0);
		if (s > buf+n) {
			if (!strncmp(s,"k",1)) p->data *= 1024;
		}
		p->time *= 1000;
		p++; if (progsize++ >= PROGSZ) {
			fprintf(stderr,"program too long\n");
			exit (5);
		}
		if (p->flow >= FLOWS) {
			fprintf(stderr,"flow %d not exists\n",p->flow);
			exit (5);
		}
	}
	fprintf(stderr,"read program %d commands\n",progsize);
   	if (!progsize) {
		fprintf(stderr,"no program\n"); exit (5);
	}
}

void execprog ()
{
	struct progdata *p = prog + progcounter;
    for (; progcounter < progsize; progcounter++, p++) {
		if (p->time > us) break;
		switch (p->code) {
			case 'X': /* exit simulator */
				sigint = 1; break;
			case 'R': /* R flow rate; sets rate of flow in Bps; 0 = stop */
				ftab[p->flow].rate = p->data; 
				if (maxflow < p->flow) maxflow = p->flow;
				if (!ftab[p->flow].pktsize) ftab[p->flow].pktsize = 500;
				break;
			case 'J': /* J flow jitt; set jitter in percents */
				ftab[p->flow].jitter = p->data; break;
			case 'S': /* S flow pktsize */
				ftab[p->flow].pktsize = p->data; break;
			case 'P': /* P flow priocode; uses SO_PRIORITY */
				ftab[p->flow].prio = p->data; break;
			case 'G': /* G flow priocode jitter; uses SO_PRIORITY */
				ftab[p->flow].prio_rng = p->data; break;
			case 'i': /* set rx+tx interface name */
				ftab[p->flow].rx_dev = find_device(p->str,ftab[p->flow].tmac);
				/* PASS THRU */
			case 't': /* set only tx dev */
				if ((ftab[p->flow].tx_dev = find_device(p->str,ftab[p->flow].smac)) < 0 ||
						ftab[p->flow].rx_dev < 0) {
					fprintf(stderr,"bad device name: %s or no rx\n",p->str);
				}
				break;
			case 's': /* system command */
				system (p->str); break;
		}
	}
}
	
int main(int c,char *av[])
{
	unsigned long av_k1=0,av_k2=0,t_k1=0,t_k2=0;
	unsigned long av_k3=0,av_k4=0,t_k3=0,t_k4=0;
	int x,tmo,flow,diff,lcheck = 0,lwrite = 0,i,n; 
	struct flowtab *fp;
	sock = socket(PF_PACKET,SOCK_RAW,htons(ETH_P_ALL));
	assert(sock>0);
	memset (ftab,0,sizeof(ftab));
	readprog ();
	signal (SIGINT,intsig);

	while(slog_cnt < SLOGSZ && !sigint) {
		synctime ();
		/* execute program commands */
		execprog ();
		/* transmit flows */
		n = 0;
		for (i=0,fp=ftab;i<FLOWS;i++,fp++) {
			int lim = 20;
			long long ldiff = us - fp->cp; 
			fp->cp = us;
		    if (fp->bytes < fp->rate/4) 
				fp->bytes += (ldiff*fp->rate)/1000000;
			
			while (lim-- && fp->bytes > 0) {
				if (send_raw(i)) fp->wbytes+=fp->pktsize;
				n++; fp->bytes -= fp->pktsize;
			}
		}
//		fprintf(stderr,"after send %d n=%d\n",us/1000,n);
		/* well they did, recieve data */
		n = 0; tmo = 1;
		while(recv_raw(tmo)) {
			int delay; n++;
			fp = ftab + buf.flowid; tmo = 0;
			/* compute delay & read bytes */
			delay = us - buf.time;
			EWMA(fp->av_delay,delay);
			delay -= fp->av_delay;
			if (delay < 0) delay = -delay;
			EWMA(fp->av_jitter,delay);
			fp->rbytes += buf.size;
			/* globally update kernel infos */
		//	t_k1 += buf.k1; t_k2 += buf.k2;
		//	t_k3 += buf.k3; t_k4 += buf.k4;
			if (buf.k1) EWMA(av_k1,buf.k1);
			if (buf.k2) EWMA(av_k2,buf.k2);
			if (buf.k3) EWMA(av_k3,buf.k3);
			if (buf.k4) EWMA(av_k4,buf.k4);
		}
		synctime ();
//		fprintf(stderr,"after recv %d n=%d\n",us/1000,n);

#define ALIGN(X,S) (X/S*S)
		/* we have time now so that recompute stats every 100ms */
		if (us - ALIGN(lcheck,MSTIME) < MSTIME) continue;
		diff = us - lcheck; lcheck = us;
//		fprintf(stderr,"check %d diff %d\n",us/1000,diff/1000);
		for (fp = ftab,i=0;i<FLOWS;fp++,i++) {
			x = fp->rbytes*1000 / (diff/1000);
			fp->rbytes = 0; EWMA(fp->av_rate,x);
			x = fp->wbytes*1000 / (diff/1000);
			fp->wbytes = 0; EWMA(fp->av_wrate,x);
			if (!fp->av_rate) fp->av_delay = 0;
		}

		/* write stats every .5 second */
		if (us - ALIGN(lwrite,LOGTIME) < LOGTIME) continue;
		lwrite = us;
		fprintf(stderr,"store %d at %d ms\n",slog_cnt,us/1000);
		for (fp = ftab,i=0;i<FLOWS;fp++,i++) {
			stp = slog + slog_cnt;
			stp->av_delay[i] = fp->av_delay/EWMAC; 
			stp->av_rate[i] = fp->av_rate/EWMAC;
			stp->av_jitter[i] = fp->av_jitter/EWMAC; 
			stp->av_wrate[i] = fp->av_wrate/EWMAC;
		}
		stp->av_jitter[0]=av_k1/EWMAC;
		stp->av_jitter[1]=av_k2/EWMAC;
		stp->av_jitter[2]=av_k3/EWMAC;
		stp->av_jitter[3]=av_k4/EWMAC;
		slog_cnt++;
	}
	/* write result to stdout */
#if 0
	for (flow = 0; flow <= maxflow; flow++) {
		fp = ftab + flow;
		printf ("# flow no %d: time[s] rate[Bps] delay jitter[ms]\n",flow+1);
		for (i = 0, stp = slog;i < slog_cnt; i++,stp++) {
			printf("%d %d %d %d\n",i+1,stp->av_rate[flow],stp->av_delay[flow],
					stp->av_jitter[flow]);
		}
	}
#else
	for (i = 0, stp = slog;i < slog_cnt; i++,stp++) {
		printf("%d.%d",(i+1)/2,(i&1)?0:5);
		for (flow = 0; flow <= maxflow; flow++) {
			fp = ftab + flow;
			printf(" %d %d %d %d",stp->av_wrate[flow],
					stp->av_rate[flow], stp->av_delay[flow]/1000, 
					stp->av_jitter[flow]);
		}
		printf("\n");
	}
#endif
}
