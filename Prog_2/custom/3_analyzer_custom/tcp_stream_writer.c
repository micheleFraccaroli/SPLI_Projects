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
	/*if(elem.sequence_number< counter){
		printf("eJNFFOINEWNFOWEINOINEFON\n");
		return l;
	}*/
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
	printf("QUIIIII\n");
	if(L==NULL){
		printf("NULL LIST\n");
		return NULL;
	}
	printf("L!= NULL\n");
	if(((L->el.sequence_number))==(ack_num-(L->el.length))){
		tmp = L->el;
		sprintf(seq,"sport=%d dport=%d sequence_number %u ack_number %u pack --> ",tmp.sourceP,tmp.destP,tmp.sequence_number,tmp.ack_number);
		printf("%s\n",seq );
		write(fp,seq,strlen(seq));
		write(fp,L->buffer,strlen(L->buffer));
		write(fp,&nl,1);
		L=L->next;
		//return L;
		l = L;
		//return l;
	}
	if(L==NULL)return l;
	//printf("CIAOOOOCULO\n");
	prec=L;
	L=L->next;
	while(L!=NULL){
		if(((L->el.sequence_number)) == (ack_num-(L->el.length))){
			tmp = L->el;
			sprintf(seq,"sport=%d dport=%d sequence_number %u ack_number %u pack --> ",tmp.sourceP,tmp.destP,tmp.sequence_number,tmp.ack_number);
			printf("not null list %s\n",seq );
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

	//printf("NO PRINT\n");
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
	int fpCS,fpSC,payload_length;
	u_int CScounter,SCcounter;
	char *buffer,name[200];
	int i =0,test=0;
	CScounter=0;
	SCcounter=0;
	packet_struct read_element;
	lCS = NULL;
	lSC = NULL;
	printf("PREFILES\n");
	sprintf(name, "%s_%s", "ipclient","ipserver");
	fpCS = open(name,O_WRONLY|O_CREAT|O_TRUNC,0777);
	printf("%d\n",fpCS );
	sprintf(name, "%s_%s", "ipserver","ipclient");
	fpSC = open(name,O_WRONLY|O_CREAT|O_TRUNC,0777);
	printf("POSTFILES\n");
	while(read(pipe,&read_element,sizeof(packet_struct))>0){
		printf("ENTRATO %d\n",test++);
		if(read_element.FIN ==1){
			//end_flow(lCS,fpCS);
			printf("LCS\n");
			printlista(lCS);
			printf("LSC\n");
			printlista(lSC);
			//end_flow(lSC,fpSC);
			//break;
		}
		//printf("TCP_STREAM_WRITER>>>e.sequence_number=%u e.length=%d\n",read_element.sequence_number,read_element.length);
		buffer = (char*)malloc(read_element.length);
		memset(buffer,0,read_element.length);
		read(pipe,buffer,read_element.length);
		
		//if(read_element.length<=0) continue;
		/*
		for(i=0;i<4;i++)
			printf("%u",ipclient[i] );
		printf("\n");
		for(i=0;i<4;i++)
			printf("%u",read_element.sIP[i] );
		printf("\n");
		*/
		
		if(ip_match(ipserver,read_element.sIP) &&(read_element.sourceP==8080)){
			//server -> client
			if(SCcounter ==0){
				SCcounter = read_element.sequence_number+1;
			}
			if(read_element.ACK==1 && read_element.SYN==0){
				printf("SERVER -> CLIENT\n");
				lCS = write_pack_acked(lCS,read_element.ack_number,fpSC);
				if(read_element.length==0){
					//write_ack(read_element.sIP,read_element,dIP);
				}
			}
			if(read_element.length>0){
				lSC = append_to_lista(lSC,read_element,buffer,CScounter);
				SCcounter+=read_element.length;
				/*if(read_element.sequence_number == SCcounter){
					char nl = '\n';
					char seq[30];
					sprintf(seq,"sequence_number %u pack --> ",read_element.sequence_number);
					write(fpSC,seq,strlen(seq));
					write(fpSC,buffer,strlen(buffer));
					write(fpSC,&nl,1);
					SCcounter += read_element.length;
					write_lista(lSC,&SCcounter,fpSC);
				}
				else if(read_element.sequence_number>SCcounter){
					lSC = append_to_lista(lSC,read_element,buffer);
					printf("APPPEND\n");
				}*/
			}
			/*
			else if(read_element.length==0){
				if(read_element.ACK==1){
					char res[20];
					sprintf(res,"IP SEQUENCE ACK")
					write(fp,)
				}
			}*/
			//char temp[100];
			//debug
			/*

			sprintf(temp, "%d pack->",read_element.sequence_number);
			write(fpSC,temp,strlen(temp));
			write(fpSC,buffer,read_element.length);
			write(fpSC,&nl,sizeof(char));*/
			//"clientIP clientP -->/(<--) serverIP serverP SYNF ACKF SEQN ACKN PAYLOAD"

			
		}
		else if(ip_match(ipclient,read_element.sIP)){
			if(CScounter==0){
				CScounter = read_element.sequence_number+1;
				//printf("CS counter %u\n",CScounter );
			}
			if(read_element.ACK==1 && read_element.SYN ==0){
				printf("CLIENT -> SERVER\n");
				lSC = write_pack_acked(lSC,read_element.ack_number,fpSC);
				if(read_element.length==0){
					//write_ack(read_element.sIP,read_element,dIP);
				}
			}
			if(read_element.length>0){
				lCS = append_to_lista(lCS,read_element,buffer,CScounter);
				CScounter+=read_element.length;
				/*if(read_element.sequence_number == CScounter){
					char nl='\n';
					char seq[30];
					sprintf(seq,"sequence_number %u pack --> ",read_element.sequence_number);
					write(fpCS,seq,strlen(seq));
					write(fpCS,buffer,strlen(buffer));
					write(fpCS,&nl,1);
					CScounter += read_element.length;
					write_lista(lCS,&CScounter,fpCS);
				}
				else if (read_element.sequence_number>CScounter){
					lCS = append_to_lista(lCS,read_element,buffer);
					printf("append\n");
					//printlista(lCS);
				}*/
			}
			/*
			//debug
			char temp[100];
			//debug
			memset(temp,0,100);
			printf("CIAOOOO\n");
			sprintf(temp, "%d pack->",read_element.sequence_number);
			write(fpCS,temp,strlen(temp));
			write(fpCS,buffer,read_element.length);
			write(fpCS,&nl,sizeof(char));*/
		}
	}
	close(fpCS);
	close(fpSC);
	return(0);
}
