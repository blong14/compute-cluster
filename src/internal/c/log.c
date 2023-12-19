#include <stdio.h>
#include <string.h>
#include <time.h>

#include "log.h"

void logger(const char* tag, const char* message) {
    time_t now;
    time(&now);

    char* when = strtok(ctime(&now), "\n");

    fprintf(stderr, "%s [%s]: %s\n", when, tag, message);
}
