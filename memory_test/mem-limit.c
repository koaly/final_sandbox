#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {

    int i;
    char *p;

    // intro message
    printf("Starting ...\n");

    // loop 50 times, try and consume 50 MB of memory 
    for (i = 0; i < 2048; ++i) {

        // failure to allocate memory?
        if ((p = malloc(1<<20)) == NULL) {
            printf("Malloc failed at %d MB\n", i);
            return 0;
        }

        // take memory and tell user where we are at
        memset(p, 0, (1<<20));
        printf("Allocated %d to %d MB\n", i, i+1);

    }

    // exit message and return
    printf("Done!\n");
    return 0;

}