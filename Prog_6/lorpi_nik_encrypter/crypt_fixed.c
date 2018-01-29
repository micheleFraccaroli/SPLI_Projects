#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <stdint.h>

#define LOG_FILE "crp.log"
#define HELP "Synax: %s -f <filename> -o <filename> [-g] [-d]\n-h for more informations\n"

#define CHUNK_SIZE 16
#define MAX_NAME 256



uint8_t *f(const uint8_t *crp_chunk, uint8_t *half_chunk, uint32_t half, uint8_t key) {
  for (uint32_t i = 0; i < half; i++)
    half_chunk[i] = (crp_chunk)[i] ^ key;
  return half_chunk;
}

uint8_t *crpt(const uint8_t *chunk, uint8_t *crp_chunk, uint32_t len, uint8_t key) {
  uint32_t half = len / 2;
  uint8_t *half_chunk = (uint8_t*)malloc(half * sizeof(uint8_t));
  memcpy(crp_chunk, chunk + half, half);
  memcpy(crp_chunk + half, chunk, half);
  f(crp_chunk, half_chunk, half, key);
  for (uint32_t i = 0; i < half; i++) {
    (crp_chunk + half)[i] ^= half_chunk[i];
  }
  return crp_chunk;
}

int main(int argc, char *argv[]) {
  uint8_t flags;  //0x01:file;0x02:output
  uint8_t chunk[CHUNK_SIZE], crp_chunk[CHUNK_SIZE];
  uint8_t key, nbytes;
  uint8_t constantkey;
  
  char fname[MAX_NAME], gname[MAX_NAME], o = 0;
  FILE *f = NULL, *g = NULL;

  memset(fname, 0, MAX_NAME);
  memset(gname, 0, MAX_NAME);
  memset(chunk, 0, CHUNK_SIZE);

  while ((o = getopt(argc, argv, "f:o:k:gsdh")) != -1) {
    switch (o)
      {
      case 'f':
        flags |= 0x01;
        strcpy(fname, optarg);
        break;
      case 'o':
        flags |= 0x02;
        strcpy(gname, optarg);
        break;
      case 'g':
        flags |= 0x04;
        printf("DEBUG MODE ON\n");
        break;
      case 'd':
        flags |= 0x08;
        break;
      case 'k':
        flags |= 0x10;
        constantkey = atoi(optarg);
        break;
      case 'h':
        printf(HELP, argv[0]);
        return 0;
      default:
        printf("ERROR! "HELP, argv[0]);
        exit(1);
      }
  }
  
  if (!(flags & 0x01)) {
    printf("ERROR! "HELP, argv[0]);
    exit(1);
  }
  
  if ((f = fopen(fname, "rb")) == NULL) {
    printf("ERROR! File not found.\n");
    exit(2);
  }
  if ((g = fopen(gname, "wb")) == NULL) {
    printf("ERROR! Error opening %s.\n", gname);
    exit(2);
  }
  key = constantkey;
  while (1) {
    memset(chunk, 0, CHUNK_SIZE);
    nbytes = fread(chunk, sizeof(uint8_t), CHUNK_SIZE, f);
    printf("nbytes = %d\n",nbytes);
    if(nbytes == 0)
      break;
    for (uint32_t i = 0; i < (sizeof(key) * 8); i++) { //(sizeof(key) * 8 - 1)
      uint8_t t = 0;
      //printf("qui ~ %u\n", (sizeof(key) * 8 - 1));
      printf("KEY: %u\n", t);
      crpt(chunk, crp_chunk, CHUNK_SIZE, key);
      memcpy(chunk, crp_chunk, CHUNK_SIZE);
      t = key & 0x01;
      printf("KEY: %u, %d\n", t, key);
      key >>= 1;
      key |= (t << 7);
    }
    key = constantkey;
    fwrite(crp_chunk, sizeof(uint8_t), CHUNK_SIZE, g);
    if (nbytes < CHUNK_SIZE)
      break;
  }
  memset(chunk, 0, CHUNK_SIZE);
  if (nbytes > 0) chunk[CHUNK_SIZE - 1] = CHUNK_SIZE - nbytes;
  for (uint32_t i = 0; i < (sizeof(key) * 8); i++) {
      uint8_t t = 0;
      crpt(chunk, crp_chunk, CHUNK_SIZE, key);
      memcpy(chunk, crp_chunk, CHUNK_SIZE);
      t = key & 0x01;
      key >>= 1;
      key |= (t << 7);
    }
  fwrite(crp_chunk, sizeof(uint8_t), CHUNK_SIZE, g);
    
  fclose(f);
  fclose(g);
  return 0;
}
