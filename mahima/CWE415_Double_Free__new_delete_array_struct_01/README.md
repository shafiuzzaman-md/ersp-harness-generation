# CWE415_Double_Free__new_delete_array_struct_01 Harness

This directory contains my KLEE harness for the Juliet C++ test case  
“CWE415_Double_Free__new_delete_array_struct_01.cpp”

-"instrumented_CWE415_s02_bad.c"
  -Keeps only the "CWE415_Double_Free__new_delete_array_struct_01_bad()" function  
  - The function
    1. Allocates a heap array using new twoIntsStruct[100]
    2. Calls delete[] data once (correct)
    3. Calls delete[] data a second time (double free bug)

-"driver_CWE415_s02_bad.c"  
  -Harness driver with a simple main() that calls the bad function once  
  -No symbolic inputs are needed because the double free occurs deterministically

I built the harness by doing
clang++-14 -emit-llvm -c -g -O0 driver_CWE415_s02_bad.cpp -o harness_415_s02.bc

