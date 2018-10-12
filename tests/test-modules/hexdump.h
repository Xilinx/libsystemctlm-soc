#ifndef HEXDUMP_H_
#define HEXDUMP_H_
#include <stdio.h>
#include <stdlib.h>

void hexdump(const char *prefix, unsigned char *buf, size_t len)
{
        unsigned char *u8 = buf;
        size_t i;

        if (prefix)
                printf("%s @ %p len=%u:\n", prefix, buf, (unsigned int) len);
        for (i = 0; i < len; i++) {
                if ((i % 16) == 0)
                        printf("%u: ", (unsigned int) i);
                printf("%2.2x ", u8[i]);
                if (((i + 1) % 16) == 0)
                        putchar('\n');
        }
        putchar('\n');
}
#endif
