#!/bin/sh

if [ -z "$1" ] ; then
    echo "Usage: $0 SYSTEM [GCC [\"CFLAGS\"]]"
    echo "   SYSTEM: UINT32 | UINT64 | MMX | SSE | ALTIVEC"
    exit 1
fi

cd `dirname $0`

if [ ! -d "build" ] ; then
    mkdir build
fi
cd build

SYSTEM="$1"
ARG_GCC="$2"
ARG_CFLAGS="$3"

VER="1.1.0"
ARC="libdvbcsa-$VER.tar.gz"
URL="http://download.videolan.org/pub/videolan/libdvbcsa/$VER/$ARC"

err()
{
    CDIR=`pwd`
    echo "failed to download libdvbcsa"
    echo "please, download $URL"
    echo "to $CDIR"
    exit 1
}

download()
{
    if [ -d "libdvbcsa" ] ; then
        return 0
    fi

    if [ ! -f "$ARC" ] ; then
        DCMD=""

        if which curl >/dev/null ; then
            DCMD="curl -O"
        elif which wget >/dev/null ; then
            DCMD="wget"
        elif which fetch >/dev/null ; then
            DCMD="fetch"
        else
            err
        fi

        $DCMD $URL
        if [ $? -ne 0 ] ; then
            err
        fi
    fi

    tar -xf $ARC
    mv libdvbcsa-$VER libdvbcsa
}

download
cd libdvbcsa

GCC="gcc"
if [ -n "$ARG_GCC" ] ; then
    GCC="$ARG_GCC"
fi
AR=`echo $GCC | sed 's/gcc$/ar/'`

CFLAGS="-O3 -fPIC -I. -funroll-loops --param max-unrolled-insns=500"
if [ -n "$ARG_CFLAGS" ] ; then
    CFLAGS="$CFLAGS $ARG_CFLAGS"
fi

cpucheck_c()
{
    cat <<EOF
#include <stdio.h>
int main()
{
#if defined(__i386__) || defined(__x86_64__)
    unsigned int eax, ebx, ecx, edx;
    __asm__ __volatile__ (  "cpuid"
                          : "=a" (eax)
                          , "=b" (ebx)
                          , "=c" (ecx)
                          , "=d" (edx)
                          : "a"  (1));

    if(ecx & (0x00080000 /* 4.1 */ | 0x00100000 /* 4.2 */ )) printf("-msse -msse2 -msse4");
    else if(ecx & 0x00000001) printf("-msse -msse2");
    else if(edx & 0x04000000) printf("-msse -msse2");
    else if(edx & 0x02000000) printf("-msse");
    else if(edx & 0x00800000) printf("-mmmx");
#endif
    return 0;
}
EOF
}

cpucheck()
{
    CPUCHECK="./cpucheck"
    cpucheck_c | $GCC -Werror -O2 -fno-pic -o $CPUCHECK -x c - >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
        $CPUCHECK
        rm $CPUCHECK
    fi
}

case "$SYSTEM" in
"UINT32")
    TRANSPOSE="32"
    ;;
"UINT64")
    TRANSPOSE="64"
    ;;
"MMX")
    TRANSPOSE="64"
    CFLAGS="$CFLAGS -mmmx"
    ;;
"SSE")
    TRANSPOSE="128"
    CPUFLAGS=`cpucheck`
    if [ -n "$CPUFLAGS" ] ; then
        $GCC $CFLAGS $CPUFLAGS -E -x c /dev/null >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            CFLAGS="$CFLAGS $CPUFLAGS"
        fi
    fi
    ;;
"ALTIVEC")
    TRANSPOSE="128"
    ;;
*)
    echo "wrong SYSTEM option"
    exit 1
    ;;
esac

posix_memalign_test_c()
{
    cat <<EOF
#include <stdio.h>
#include <stdlib.h>
int main(void) { void *p = NULL; return posix_memalign(&p, 32, 128); }
EOF
}

check_posix_memalign()
{
    posix_memalign_test_c | $GCC -Werror -o /dev/null -x c - >/dev/null 2>&1
}

HAVE_POSIX_MEMALIGN=""

if check_posix_memalign ; then
    HAVE_POSIX_MEMALIGN="#define HAVE_POSIX_MEMALIGN 1"
fi

cat >config.h <<EOF
#define STDC_HEADERS 1

#define DVBCSA_USE_$SYSTEM 1

#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STDINT_H 1

$HAVE_POSIX_MEMALIGN
EOF

OUT=""
LNK=""

CCSYSTEM=`$GCC -dumpmachine`
case "$CCSYSTEM" in
*"darwin"*)
    OUT="libdvbcsa.$VER.dylib"
    LNK="libdvbcsa.dylib"
    ;;
*"mingw"*)
    OUT="libdvbcsa.dll"
    ;;
*)
    OUT="libdvbcsa.so.$VER"
    LNK="libdvbcsa.so"
esac

cat >Makefile <<EOF
# generated by libdvbcsa.sh

MAKEFLAGS = -rR --no-print-directory

OUT = $OUT
LNK = $LNK
ALIB = libdvbcsa.a

LPATH = /usr/lib
IPATH = /usr/include/dvbcsa

CC = $GCC
LD = $GCC
AR = $AR

CFLAGS = $CFLAGS
LDFLAGS = -shared

OBJS = src/dvbcsa_key.o src/dvbcsa_block.o src/dvbcsa_algo.o src/dvbcsa_stream.o
BSOBJS = src/dvbcsa_bs_algo.o src/dvbcsa_bs_block.o src/dvbcsa_bs_key.o src/dvbcsa_bs_stream.o \
  src/dvbcsa_bs_transpose.o src/dvbcsa_bs_transpose$TRANSPOSE.o

.PHONY: all clean install

all: \$(OUT) \$(ALIB)

clean:
	@echo "CLEAN"
	@rm -f \$(OUT) \$(OBJS) \$(BSOBJS)

\$(OUT): \$(OBJS) \$(BSOBJS)
	@echo "BUILD: \$@"
	@\$(LD) \$(LDFLAGS) \$^ -o \$@

\$(ALIB): \$(OBJS) \$(BSOBJS)
	@echo "BUILD: \$@"
	@\$(AR) cru \$@ \$^

%.o: %.c
	@echo "   CC: \$@"
	@\$(CC) \$(CFLAGS) -c \$< -o \$@

install: \$(OUT)
	@echo "INSTALL: \$(LPATH)/\$(OUT)"
	@cp \$(OUT) \$(LPATH)/\$(OUT)
	@echo "INSTALL: \$(LPATH)/\$(LNK)"
	@ln -nfs \$(OUT) \$(LPATH)/\$(LNK)
	@echo "INSTALL: \$(IPATH)/dvbcsa.h"
	@mkdir -p \$(IPATH)
	@cp src/dvbcsa/dvbcsa.h \$(IPATH)/dvbcsa.h

EOF

make
if [ $? -eq 0 ] ; then
    echo ""
    echo "make complete"
    echo "to install libdvbcsa use: sudo make -C build/libdvbcsa install"
    echo "or build astra for built-in use"
fi
cd ..
