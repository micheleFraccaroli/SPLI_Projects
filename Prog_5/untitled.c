#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FRST 0x21
#define LAST 0x7e

int main(int argc, char *argv[]) {
  int offset = 3, i;
  char gname[255], c = 0, t = 0, buf[4];
  FILE *f = NULL, *g = NULL;

  memset(gname, 0, sizeof(gname));

  if (argc < 2) {
    printf("ERROR! You must specify filename!\n%s <filename> [<offset>]\n", argv[0]);
    exit(1);
  }

  if ((f = fopen(argv[1], "rb")) == NULL) {
    printf("ERROR! File not found.\n");
    exit(2);
  }
  if (argc == 3)
      offset = atoi(argv[2]);

  for(i=1; i <= offset; i++){
    strcpy(gname, "Decrypt");
    strcat(gname, ".dcry");
    sprintf(buf, "%d", i);
    strcat(gname, buf);

    if ((g = fopen(gname, "wb")) == NULL) {
      printf("ERROR! Error opening %s.\n", gname);
      exit(2);
    }
    
    c = (char)fgetc(f);
    printf("CI sono -------->: %c\n", c);
    do {
      t = c;
      if (c >= FRST && c <= LAST) {
        c -= FRST;
        printf("LA CI VALE: %c\n", c);
        c -= i;
        printf("RIGA 46----> c: %c\n", c);
        if (c < 0) c += (LAST - FRST + 1);
        c %= (LAST - FRST + 1);
        c += FRST;
        printf("RIGA 50----> c: %c\n", c);
      }
      fputc((int)c, g);
      printf("%c -> %c | 0x%x -> 0x%x\n", t, c, t, c);
      printf("E QUA LA C VALE A RIGA 54: %c\n", c);
      c = (char)fgetc(f);
      printf("E QUA LA C VALE: %c\n", c);
    } while (c != EOF);
    
  }
  fclose(g);
  fclose(f);
  return 0;
}
