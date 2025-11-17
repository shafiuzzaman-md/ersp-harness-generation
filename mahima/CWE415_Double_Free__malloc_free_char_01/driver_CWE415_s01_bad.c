// driver_CWE415_s01_bad.c

#include "instrumented_CWE415_s01_bad.c" 

int main(void) {
    // There are no symbolic inputs here, because this particular Juliet test triggers the double-free deterministically.
    CWE415_Double_Free__malloc_free_char_01_bad();
    return 0;
}
