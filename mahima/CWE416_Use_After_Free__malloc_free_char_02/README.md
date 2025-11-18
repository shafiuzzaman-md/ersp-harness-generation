# CWE416_Use_After_Free__malloc_free_char_02 Harness

This directory contains my KLEE harness for the Juliet C++ test case  
"CWE416_Use_After_Free__malloc_free_char_02.c"

-"instrumented_CWE416_s02_bad.c"
  -Keeps only the "CWE416_Use_After_Free__malloc_free_char_02_bad" function  
  - The function
    1. Allocates a char * buffer with malloc(100)
    2. Copies a string into the buffer using strcpy
    3. Frees the buffer using free(data)
    4. Calls printLine(data) after freeing it, which is the use-after-free bug. Juliet’s original printLine comes from an external support library, so here it is replaced with a stub that directly dereferences the pointer.

-"driver_CWE416_s02_bad.c"  
  -Harness driver with a simple main() that calls the bad function once  
  -No symbolic inputs are needed because the double free occurs deterministically

I built the harness by doing
clang-14 -emit-llvm -c -g -O0 driver_CWE416_s02_bad.c -o harness_416_s02.bc

LLM Prompt:
"Create an instrumental file and driver file for this Juliet test case:
https://github.com/arichardson/juliet-test-suite-c/blob/master/testcases/CWE416_Use_After_Free/CWE416_Use_After_Free__malloc_free_char_02.c

The instrumented file should contain only the bad() function (CWE416_Use_After_Free__malloc_free_char_02_bad), plus any minimal type definitions and includes needed, with no good() functions or main(). The driver file should define main(), include the instrumented file, and call the bad() function once."
