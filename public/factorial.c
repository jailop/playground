#include <stdio.h>

long factorial(long n) {
    if (n < 2) return n;
    return n * factorial(n - 1);
}

int main(void) {
    printf("%ld\n", factorial(5));
    return 0;
}
