// driver_CWE416_s01_bad.c

#include "instrumented_CWE416_s01_bad.c"

int main(void) {
    CWE416_Use_After_Free__malloc_free_char_01_bad();
    return 0;
}
