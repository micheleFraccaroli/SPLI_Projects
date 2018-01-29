#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <stdint.h>

int main(int argc, char *argv[]) {
  FILE *f = NULL;
  uint8_t chunk[16];
  f = fopen("test.bin", "wb");
  memset(chunk, 0xA5, 16);
  fwrite(chunk, sizeof(uint8_t), 16, f);
  fclose(f);
}
