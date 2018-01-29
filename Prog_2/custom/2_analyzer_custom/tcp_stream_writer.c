#include "my.h"
#include <sys/stat.h>
#include <fcntl.h>

typedef struct list_el{
	packet_struct el;
	char *buffer;
	struct list_el *next;
}list_element;

typedef list_element *list;


list append_to_lista(list l, packet_struct elem, char buf[]){
	list tmp;
	char *payload;
	list L;
	list prec=NULL;
	L=l;
	strcpy(payload,buf);
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

int write_lista(list l, int *counter, int fp){
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
			printf("HO BREAKKATO\n");
			break;
		}
	}
	return(ok);
}
/*
int ip_to_string(u_char *ip){
	char buffer[16];
	int i =0;
	memset(buffer,0,16);
	for(i=0;i<4;i++){
		fprintf(buffer, "%d.\n", );
	}
}*/



int tcp_stream_writer(int pipe,u_char *ipclient,u_char *ipserver){
	//settaggio pipe
	list lCS,lSC;
	char nl='\n';
	int CScounter,SCcounter,fpCS,fpSC,payload_length;
	char *buffer,name[200];
	int i =0,test=0;
	CScounter=0;
	SCcounter=0;
	packet_struct read_element;
	lCS = NULL;
	lSC = NULL;
	printf("PREFILES\n");
	sprintf(name, "%s_%s", "ipclient","ipserver");
	fpCS = open(name,O_WRONLY|O_CREAT,0777);
	printf("%d\n",fpCS );
	sprintf(name, "%s_%s", "ipserver","ipclient");
	fpSC = open(name,O_WRONLY|O_CREAT,0777);
	printf("POSTFILES\n");
	while(read(pipe,&read_element,sizeof(packet_struct))>0){
		printf("ENTRATO %d\n",test++);
		/*if(read_element.FIN ==1){
			end_flow(lCS,fpCS);
			end_flow(lSC,fpSC);
			break;
		}*/
		printf("TCP_STREAM_WRITER>>>e.sequence_number=%u e.length=%d\n",read_element.sequence_number,read_element.length);
		buffer = (char*)malloc(read_element.length);
		memset(buffer,0,read_element.length);
		read(pipe,buffer,read_element.length);
		
		if(read_element.length<=0) continue;
		
		for(i=0;i<4;i++)
			printf("%u",ipclient[i] );
		printf("\n");
		for(i=0;i<4;i++)
			printf("%u",read_element.sIP[i] );
		printf("\n");
		
		
		if(ip_match(ipserver,read_element.sIP)){
			//server -> client
			char temp[100];
			//debug

			sprintf(temp, "%d pack->",read_element.sequence_number);
			write(fpSC,temp,strlen(temp));
			write(fpSC,buffer,read_element.length);
			write(fpSC,&nl,sizeof(char));
			

			/*
			if(read_element.sequence_number == SCcounter){
				write(fpSC,buffer,strlen(buffer)*sizeof(char));
				SCcounter += payload_length;
				write_lista(lSC,&SCcounter,fpSC);
			}
			else{
				lSC = append_to_lista(lSC,read_element,buffer);
			}*/

			
		}
		else if(ip_match(ipclient,read_element.sIP)){
			//client -> server
			//debug
			char temp[100];
			//debug
			memset(temp,0,100);
			printf("CIAOOOO\n");
			sprintf(temp, "%d pack->",read_element.sequence_number);
			write(fpCS,temp,strlen(temp));
			write(fpCS,buffer,read_element.length);
			write(fpCS,&nl,sizeof(char));
			

			/*
			if(read_element.sequence_number == CScounter){
				write(fpCS,buffer,strlen(buffer)*sizeof(char));
				CScounter += payload_length;
				write_lista(lCS,&CScounter,fpCS);
			}
			else{
				lCS = append_to_lista(lCS,read_element,buffer);
			}*/
		}
	}
	close(fpCS);
	close(fpSC);
	return(0);
}
