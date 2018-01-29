#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#define FRST 0x21
#define LAST 0x7e

#define LOG_FILE "crp.log"

int main(int argc, char *argv[]) {
  int offset = 3, debug = 0;
  char fname[255], gname[255], c = 0, t = 0, o = 0;
  FILE *f = NULL, *g = NULL, *d = NULL;

  memset(fname, 0, sizeof(fname));
  memset(gname, 0, sizeof(gname));

  while ((o = getopt(argc, argv, "f:o:g::h::")) != -1) {
    switch (o)
      {
      case 'f':
        strcpy(fname, optarg);
        break;
      case 'o':
        offset = atoi(optarg);
        break;
      case 'g':
        debug = 1;
        printf("DEBUG MODE ON\n");
        break;
      case 'h':
        printf("Synax: %s -f <filename> -o <offset> [-g]\n-h for more informations\n", argv[0]);
        return 0;
      default:
        printf("ERROR! Synax: %s -f <filename> -o <offset> [-g]\n-h for more informations\n", argv[0]);
        exit(1);
      }
  }
  
  strcpy(gname, fname);
  strcat(gname, ".crp");

  if ((f = fopen(fname, "rb")) == NULL) {
    printf("ERROR! File not found.\n");
    exit(2);
  }
  if ((g = fopen(gname, "wb")) == NULL) {
    printf("ERROR! Error opening %s.\n", gname);
    exit(2);
  }
  if(debug && ((d = fopen(LOG_FILE, "wt")) == NULL)) {
    printf("ERROR! Error opening %s.\n", LOG_FILE);
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
    if (debug) fprintf(d, "%c -> %c | 0x%x -> 0x%x\n", t, c, t, c);
    c = (char)fgetc(f);
  } while (c != EOF);

  fclose(f);
  fclose(g);
  return 0;
}
