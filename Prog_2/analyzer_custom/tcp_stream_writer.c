#include "my.h"
#include <sys/stat.h>
#include <fcntl.h>

typedef struct list_el{
	packet_struct el;
	char *buffer;
	struct list_el *next;
}list_element;

typedef list_element *list;


list append_to_lista(list l, packet_struct elem, char buf[],u_int counter){
	list tmp;
	char *payload;
	list L;
	list prec=NULL;
	L=l;
	payload = (char*) malloc(elem.length);
	memcpy(payload,buf,elem.length);
	while(L!=NULL && ((L->el.sequence_number) < elem.sequence_number)){
		prec = L;
		L = L->next;
	}
	tmp = (list) malloc(sizeof(list_element));
	tmp->el=elem;
	tmp->buffer = payload;
	tmp->next = L;
	if(L==l){
		return tmp;
	}
	else{
		prec->next = tmp;
		return l;
	}

}

int write_lista(list l, u_int *counter, int fp){
	list L =l;
	if(L==NULL) return(0);	
	while(L-> el.sequence_number == (*counter)){
		write(fp,L->buffer,sizeof(char)*(L->el.length));
		(*counter)+= L->el.length;
		if((L-> next)==NULL){
			l=NULL;
			return(0);
		}
		else{
			L = L->next;
		}
	}
	l=L;
	return(0);
}

int end_flow(list l,int fp){
	list L = l;
	while(L!= NULL){
		write(fp,L->buffer,sizeof(char)*(L->el.length));
		L = L->next;
	}
	return(0);
}

int ip_match(u_char *ip, u_char *ipstruct){
	int i;
	int ok =1;
	for(i =0;i<4;i++){
		if(ip[i]!= ipstruct[i]){
			ok=0;
			//printf("HO BREAKKATO\n");
			break;
		}
	}
	return(ok);
}

list write_pack_acked(list l,u_int ack_num,int fp){
	list L,prec;
	packet_struct tmp;
	char nl = '\n';
	char seq[100];
	L=l;
	if(L==NULL){
		return NULL;
	}

	//pacchetti in testa
	if(((L->el.sequence_number))==(ack_num-(L->el.length))){
		char sIP[20],dIP[20];
		tmp = L->el;
		sprintf(sIP,"%d.%d.%d.%d",tmp.sIP[0],tmp.sIP[1],tmp.sIP[2],tmp.sIP[3]);
		sprintf(dIP,"%d.%d.%d.%d",tmp.dIP[0],tmp.dIP[1],tmp.dIP[2],tmp.dIP[3]);
		sprintf(seq,"source = %s:%d --> dest = %s:%d SN = %u AN = %u payload = ",sIP,tmp.sourceP,dIP,tmp.destP,tmp.sequence_number,tmp.ack_number);
		write(fp,seq,strlen(seq));
		write(fp,L->buffer,strlen(L->buffer));
		write(fp,&nl,1);
		L=L->next;
		l = L;
	}

	//pacchetti a metà o fine
	if(L==NULL)return l;
	prec=L;
	L=L->next;
	while(L!=NULL){
		if(((L->el.sequence_number)) == (ack_num-(L->el.length))){
			char sIP[20],dIP[20];
			tmp = L->el;
			sprintf(sIP,"%d.%d.%d.%d",tmp.sIP[0],tmp.sIP[1],tmp.sIP[2],tmp.sIP[3]);
			sprintf(dIP,"%d.%d.%d.%d",tmp.dIP[0],tmp.dIP[1],tmp.dIP[2],tmp.dIP[3]);
			sprintf(seq,"source = %s:%d --> dest = %s:%d SN = %u AN = %u payload = ",sIP,tmp.sourceP,dIP,tmp.destP,tmp.sequence_number,tmp.ack_number);
			//printf("not null list %s\n",seq );
			write(fp,seq,strlen(seq));
			write(fp,L->buffer,strlen(L->buffer));
			write(fp,&nl,1);
			(prec->next)=(L->next);
			L=L->next;	
			//return l;
		}
		else{
			prec = L;
			L=L->next;
		}
	}


	return l;
}

void printlista(list l){
	packet_struct tmp;
	list L =l;
	while(L!=NULL){
		tmp = L->el;
		printf("sport=%d dport=%d sequence_number %u ack_number %u pack --> %s\n",tmp.sourceP,tmp.destP,tmp.sequence_number,tmp.ack_number,L->buffer);
		L=L->next;
	}
}




int tcp_stream_writer(int pipe,u_char *ipclient,u_char *ipserver){
	//settaggio pipe
	list lCS,lSC;
	char nl='\n';
	int fpCS,fpSC,payload_length;
	u_int CScounter,SCcounter;
	char *buffer,name[200];
	int i =0,test=0;
	CScounter=0;
	SCcounter=0;
	packet_struct read_element;
	lCS = NULL;
	lSC = NULL;
	sprintf(name, "%s", "tcp_stream_output");
	fpSC = open(name,O_WRONLY|O_CREAT|O_TRUNC,0777);
	printf("tcp_stream_writer init successful\n");
	while(read(pipe,&read_element,sizeof(packet_struct))>0){
		buffer = (char*)malloc(read_element.length);
		memset(buffer,0,read_element.length);
		read(pipe,buffer,read_element.length);
		
		if(ip_match(ipserver,read_element.sIP) &&(read_element.sourceP==8080)){
			//server -> client
			if(read_element.ACK==1 && read_element.SYN==0){
				lCS = write_pack_acked(lCS,read_element.ack_number,fpSC);
			}
			if(read_element.length>0){
				lSC = append_to_lista(lSC,read_element,buffer,CScounter);
			}

			
		}
		else if(ip_match(ipclient,read_element.sIP)){
			//client -> server
			if(read_element.ACK==1 && read_element.SYN ==0){
				lSC = write_pack_acked(lSC,read_element.ack_number,fpSC);
			}
			if(read_element.length>0){
				lCS = append_to_lista(lCS,read_element,buffer,CScounter);
			}
			
		}
	}
	//close(fpCS);
	close(fpSC);
	return(0);
}
