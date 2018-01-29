#include "my.h"
#include <fcntl.h>

//DEBUG
/*
typedef struct PACKET_STRUCT {
  int test[4];
  char kill;
  int length;
} packet_struct;
*/

/*
void tcp_stream_writer(int r, char* ipsrv, char* ipclnt){
  packet_struct e;
  int init=1;
  u_int first=0;
  char *bff;
  int i=0,j=0;
  while(1){
    read(r,&e,sizeof(packet_struct));
    bff=(char*)malloc(e.length);
    read(r,bff,e.length);
    if(init)
      first=e.sequence_number;
    printf("TCP_STREAM_WRITER>>>i=%d e.sequence_number=%u relative=%d e.length=%d|bff= ",i++,e.sequence_number,e.sequence_number-first,e.length);
    for(j=0;j<e.length;j++)
      printf("%xx0 ",bff[j]);
    printf("\n");
    //sleep(1);
  }
}
*/
//END DEBUG






typedef struct BUFFER_ELEMENT{
  int length;
  char *bff;
  struct BUFFER_ELEMENT *next;
} buffer_element;

typedef buffer_element *buffer;

int flag = 1;

buffer push(buffer b1, buffer b2) {
  buffer tmp = b2;
  if(b2 == NULL)
    return b1;
  while(tmp->next != NULL)
    tmp = tmp->next;
  tmp->next = b1;
  return b2;
}

char * generateBff(packet_struct e, const char *pkt, int *length) {
  char *bff;
  bff = (char*)malloc(sizeof(packet_struct) + e.length);
  memcpy(bff, &e, sizeof(packet_struct));
  memcpy(bff + sizeof(packet_struct), pkt, e.length);
  (*length) = sizeof(packet_struct) + e.length;
  return bff;
}

buffer generateBuffer(int length, char *bff) {
  buffer b = (buffer)malloc(sizeof(buffer_element));
  b->length = length;
  b->bff = bff;
  return b;
}

buffer tryRead(int r) {
  int rb, len, i;
  char *pkt, *bff;
  packet_struct e;
  rb = read(r, &e, sizeof(packet_struct));
  if (rb > 0) {
    len = e.length;
    pkt = (char *)malloc(len);
    memset(pkt, 0, len);
    rb = 0;
    while(rb != len)
      rb = read(r, pkt, len);
    bff = generateBff(e, pkt, &len);
  } else
    return NULL;
  return generateBuffer(len, bff);;
}

int tryWrite(int w, buffer b) {
  int wb;
  wb = write(w, b->bff, b->length);
  return wb;
}

int buffer_process(int r, u_char *ipsrv, u_char *ipclnt) {
  int pid, w, len;
  int p[2];
  pipe(p);
  buffer b = NULL, btmp = NULL;
  char *pkt, *bff;
  
  if ((pid = fork()) > 0) {
    close(p[1]);
    tcp_stream_writer(p[0], ipsrv, ipclnt);
    close(p[0]);
  } else if (pid == 0) {
    close(p[0]);
    w = p[1];
    
    fcntl(r, F_SETFL, fcntl(r, F_GETFL) | O_NONBLOCK);
    fcntl(w, F_SETFL, fcntl(w, F_GETFL) | O_NONBLOCK);
    
    while(flag){
      btmp = tryRead(r);
      if(btmp != NULL)
        b = push(btmp, b);
      while(b != NULL) {
        btmp = b;
        if(tryWrite(w, btmp) < 0)
          break;
        b = btmp->next;
      }
    }
    
    while(b != NULL){
      btmp = b;
      if(tryWrite(w, btmp) > 0)
        b = btmp->next;
    }
    
    close(w);
  } else
    return 0;
  return 1;
}




//DEBUG
/*
int main() {
  int pp[2], pid, i=0,k,l,w1,w2;
  char *a, *b, alph[]={'a','b','c','d','e'}, *bff;
  packet_struct e;
  pipe(pp);
  if((pid = fork())>0){
    close(pp[0]);
    while(1){
      k=i%5;
      memset(&e.test,1,sizeof(e.test));
      e.kill=0;
      e.length=k+1;
      bff=(char*)malloc(e.length);
      for(l=0;l<e.length;l++){
        bff[l]=alph[l];
      }
      w1=write(pp[1],&e,sizeof(packet_struct));
      w2=write(pp[1],bff,e.length);
      i++;
      printf("MAIN>>>i=%d:k=%d:len=%d:w1=%d:w2=%d\n",i,k,e.length,w1,w2);
      sleep(0);
    }
    close(pp[1]);
  }else if(pid==0){
    close(pp[1]);
    buffer_process(pp[0], a, b);
    close(pp[0]);
  }else{
    return 1;
  }
  return 0;
}
*/
//END DEBUG
