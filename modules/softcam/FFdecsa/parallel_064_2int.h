/* FFdecsa -- fast decsa algorithm
 *
 * Copyright (C) 2003-2004  fatih89r
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


struct group_t{
  unsigned int s1;
  unsigned int s2;
};
typedef struct group_t group;

#define GROUP_PARALLELISM 64

static inline group FF0(void){
  group res;
  res.s1=0x0;
  res.s2=0x0;
  return res;
}

static inline group FF1(void){
  group res;
  res.s1=0xffffffff;
  res.s2=0xffffffff;
  return res;
}

static inline group FFAND(group a,group b){
  group res;
  res.s1=a.s1&b.s1;
  res.s2=a.s2&b.s2;
  return res;
}

static inline group FFOR(group a,group b){
  group res;
  res.s1=a.s1|b.s1;
  res.s2=a.s2|b.s2;
  return res;
}

static inline group FFXOR(group a,group b){
  group res;
  res.s1=a.s1^b.s1;
  res.s2=a.s2^b.s2;
  return res;
}

static inline group FFNOT(group a){
  group res;
  res.s1=~a.s1;
  res.s2=~a.s2;
  return res;
}


/* 64 rows of 64 bits */

static inline void FFTABLEIN(unsigned char *tab, int g, unsigned char *data){
  *(((int *)tab)+2*g)=*((int *)data);
  *(((int *)tab)+2*g+1)=*(((int *)data)+1);
}

static inline void FFTABLEOUT(unsigned char *data, unsigned char *tab, int g){
  *((int *)data)=*(((int *)tab)+2*g);
  *(((int *)data)+1)=*(((int *)tab)+2*g+1);
}

static inline void FFTABLEOUTXORNBY(int n, unsigned char *data, unsigned char *tab, int g){
  int j;
  for(j=0;j<n;j++){
    *(data+j)^=*(tab+8*g+j);
  }
}

struct batch_t{
  unsigned int s1;
  unsigned int s2;
};
typedef struct batch_t batch;

#define BYTES_PER_BATCH 8

static inline batch B_FFAND(batch a,batch b){
  batch res;
  res.s1=a.s1&b.s1;
  res.s2=a.s2&b.s2;
  return res;
}

static inline batch B_FFOR(batch a,batch b){
  batch res;
  res.s1=a.s1|b.s1;
  res.s2=a.s2|b.s2;
  return res;
}

static inline batch B_FFXOR(batch a,batch b){
  batch res;
  res.s1=a.s1^b.s1;
  res.s2=a.s2^b.s2;
  return res;
}


static inline batch B_FFN_ALL_29(void){
  batch res;
  res.s1=0x29292929;
  res.s2=0x29292929;
  return res;
}
static inline batch B_FFN_ALL_02(void){
  batch res;
  res.s1=0x02020202;
  res.s2=0x02020202;
  return res;
}
static inline batch B_FFN_ALL_04(void){
  batch res;
  res.s1=0x04040404;
  res.s2=0x04040404;
  return res;
}
static inline batch B_FFN_ALL_10(void){
  batch res;
  res.s1=0x10101010;
  res.s2=0x10101010;
  return res;
}
static inline batch B_FFN_ALL_40(void){
  batch res;
  res.s1=0x40404040;
  res.s2=0x40404040;
  return res;
}
static inline batch B_FFN_ALL_80(void){
  batch res;
  res.s1=0x80808080;
  res.s2=0x80808080;
  return res;
}


static inline batch B_FFSH8L(batch a,int n){
  batch res;
  res.s1=a.s1<<n;
  res.s2=a.s2<<n;
  return res;
}

static inline batch B_FFSH8R(batch a,int n){
  batch res;
  res.s1=a.s1>>n;
  res.s2=a.s2>>n;
  return res;
}


static inline void M_EMPTY(void){
}
