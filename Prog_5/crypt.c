#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FRST 0x21
#define LAST 0x7e

int main(int argc, char *argv[]) {
  int offset = 3;
  char gname[255], c = 0, t = 0;
  FILE *f = NULL, *g = NULL;

  memset(gname, 0, sizeof(gname));

  if (argc < 2) {
    printf("ERROR! You must specify filename!\n%s <filename> [<offset>]\n", argv[0]);
    exit(1);
  }

  strcpy(gname, argv[1]);
  strcat(gname, ".crp");

  if (argc == 3)
    offset = atoi(argv[2]);

  if ((f = fopen(argv[1], "rb")) == NULL) {
    printf("ERROR! File not found.\n");
    exit(2);
  }
  if ((g = fopen(gname, "wb")) == NULL) {
    printf("ERROR! Error opening %s.\n", gname);
    exit(2);
  }
  
  c = (char)fgetc(f);
  do {
    t = c;
    if (c >= FRST && c <= LAST) {
      c -= FRST;
      c += offset;
      if (c < 0) c += (LAST - FRST + 1);
      c %= (LAST - FRST + 1);
      c += FRST;
    }
    fputc((int)c, g);
    printf("%c -> %c | 0x%x -> 0x%x\n", t, c, t, c);
    c = (char)fgetc(f);
  } while (c != EOF);

  fclose(f);
  fclose(g);
  return 0;
}
