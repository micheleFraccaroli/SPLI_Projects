#include "my.h"

void liv4(u_int type,u_int len,const u_char *p){
  int ihl,flag,i,pi[2],pid,j;
  u_int dsap,ssap;
  u_int sourceP, destP;
  u_long seq_num,ack_num;
  struct filt_tcp *aux_tcp;
  //struct tcp_stream_struct *tcp_flow;
  packet_struct *pkt_str;
  struct filt_udp *aux_udp;
  u_int urg;
  const u_char *mp;
  u_char ff; 
  
  switch(type){
  case 6:
    if(!r_tcp)return;  
    ssap=ntohs(*(u_int *)p);
    dsap=ntohs(*(u_int *)(p+2));
    flag=0;

    for(aux_tcp=filt_tcp;aux_tcp!=NULL;aux_tcp=aux_tcp->next){
      if(aux_tcp->ssap!=ssap&&aux_tcp->ssap!=0){
        	flag=1;
        	continue;
      }
      if(aux_tcp->dsap!=dsap&&aux_tcp->dsap!=0){
        	flag=1;
        	continue;
      }
      flag=0;
      break;
    }

    seq_num=ntohl(*(u_long *)(p+4));
    ack_num=ntohl(*(u_long *)(p+8));
    urg=ntohl(*(u_int *)(p+18));
    ihl=((*(p+12))&0xf0)/4;
    ff=*(p+13);

    if(p_tcp){
      colore(4);
      myprintf("TCP  |");
      myprintf("%d -> %d",ssap,dsap);
      myprintf(" Seq:%lu",seq_num);
      if(ff&0x20)myprintf(" URG:%d",urg);
      if(ff&0x10)myprintf(" ACK:%lu",ack_num);
      if(ff&0x08)myprintf(" PSH");
      if(ff&0x04)myprintf(" RST");
      if(ff&0x02&&ack_num==0)myprintf(" REQ"); /* SYN */
      if(ff&0x02&&ack_num==1)myprintf(" ACP"); /* SYN */
      if(ff&0x01)myprintf(" FIN");
      myprintf("\n");
    }
    
    if(s_tcp){
      pkt_str=(packet_struct*)malloc(sizeof(packet_struct));
      memset(pkt_str,0,sizeof(packet_struct));

      if(flow_flag==0 && (tcp_flow->destP)==dsap && (ff&0x02)!=0 && (tcp_flow->ip_flag)) {
        //printf("SYN\n");
        flow_flag = 1;
        tcp_flow->sourceP=ssap;
      }
      
      if(flow_flag==1){
        if(tcp_flow->ip_flag && ((tcp_flow->sourceP == ssap && tcp_flow->destP == dsap)|| (tcp_flow->sourceP == dsap && tcp_flow->destP == ssap) )){

          pkt_str->sourceP = ssap;
          pkt_str->destP = dsap;
          if(tcp_flow->sourceP == ssap) {
            memcpy(pkt_str->sIP, tcp_flow->sIP, 4);
          }
          else{
            memcpy(pkt_str->sIP, tcp_flow->dIP, 4);
          }
          if(tcp_flow->destP == dsap) {
            memcpy(pkt_str->dIP, tcp_flow->dIP, 4);
          }
          else{
            memcpy(pkt_str->dIP, tcp_flow->sIP, 4);
          }
          pkt_str->length = len-ihl;
          pkt_str->sequence_number = seq_num;
          
          pkt_str->ack_number = ack_num;
          if(ff&0x10!=0)pkt_str->ACK=1;
          if(ff&0x02!=0)pkt_str->SYN=1;
          if(ff&0x01!=0)pkt_str->FIN=1;
          
          pkt_str->ACK = ((ff&0x10)>>4);
          pkt_str->SYN = ((ff&0x02)>>1);
          pkt_str->FIN = ((ff&0x01));
          /*
          printf("\e[0mLIV4>>>pkt_str: ");
          printf("len=%d ",pkt_str->length);
          printf("sn=%u ",pkt_str->sequence_number);
          printf("an=%u ",pkt_str->ack_number);
          printf("ACK=%u ",pkt_str->ACK);
          printf("SYN=%u ",pkt_str->SYN);
          printf("FIN=%u ",pkt_str->FIN);
          printf("\n");
          */
          if(pkt_str->FIN)h4[0]++;
          if(h4[0]>0&&pkt_str->ACK)h4[1]++;

          //printf("LIV4>>>h4[0]=%d h4[1]=%d\n",h4[0],h4[1]);
          
          //if(ff&0x01!=0){
          if(h4[0]==2&&h4[1]==2){
            flow_flag=0;
            write(fpipe[1], pkt_str, sizeof(pkt_str));
          }
          else{
            write(fpipe[1], pkt_str, sizeof(packet_struct));
            write(fpipe[1], p+ihl, len-ihl);
          }
        }
      }
    }

    if(flag){
      filt_kill=1;
      return;
    }
    liv7(len-ihl,p+ihl);
    return;
    
  case 17:
    if(!r_udp)return;  
    ssap=ntohs(*(u_int *)p);
    dsap=ntohs(*(u_int *)(p+2));
    flag=0;
    for(aux_udp=filt_udp;aux_udp!=NULL;aux_udp=aux_udp->next){
      if(aux_udp->ssap!=ssap&&aux_udp->ssap!=0){
	flag=1;
	continue;
      }
      if(aux_udp->dsap!=dsap&&aux_udp->dsap!=0){
	flag=1;
	continue;
      }
      flag=0;
      break;
    }
    if(p_udp){
      colore(4);
      myprintf("UDP  |");
      myprintf("%d -> %d",ssap,dsap);
      myprintf("\n");
    }
    if(flag){
      filt_kill=1;
      return;
    }
    liv7(len-8,p+8);
    return;

  case 2:
    if(!p_igmp)return;  
    colore(4);
    myprintf("IGMP |");
    switch((*p)){
    case 0x11:
      myprintf("Query ");
      print_ipv4(p+4);
      break;
    case 0x12:
      myprintf("Report ");
      print_ipv4(p+4);
      break;
    case 0x16:
      myprintf("Nreport ");
      print_ipv4(p+4);
      break;
    case 0x17: 
      myprintf("Leave ");
      print_ipv4(p+4);
      break;
    case 0x13:
      myprintf("DVMRP ** ");
      break;
    case 0x14:
      myprintf("PIM ** ");
      break;
    case 0x1e:
      myprintf("MRESP ** ");
      break;
    case 0x1f:
      myprintf("MTRACE ** ");
      break;
    default:
      unknown=1;
      return;
    }    
   
    myprintf("\n");
    decoded=1;
    return;

  case 1:
    if(!p_icmp)return;  
    colore(4);
    myprintf("ICMP |");
    switch((*p)&0x0f){
    case 0:
      myprintf("Echo Reply");
      break;
    case 8:
      myprintf("Echo Request");
      break;
    case 13:
      myprintf("Timestamp Request");
      break;
    case 14:
      myprintf("Timestamp Reply");
      break;

    default:
//      unknown=1;
      return;
    }   

    myprintf("\n");
    decoded=1;
    return;

  default:
    unknown=1;
    return;
  }
}
