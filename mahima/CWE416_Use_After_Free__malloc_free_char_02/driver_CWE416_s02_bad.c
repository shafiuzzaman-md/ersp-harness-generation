// driver_CWE416_s02_bad.c

#include "instrumented_CWE416_s02_bad.c"

int main(void) {
    CWE416_Use_After_Free__malloc_free_char_02_bad();
    return 0;
}
