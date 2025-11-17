LLM-Harnesses Generated For KLEE Symbolic Execution Test Cases

This project contains instrumented test cases for two common vulnerability types: Integer Overflow (CWE-190) and Divide by Zero (CWE-369). Each test case has a corresponding driver and instrumentation file to run with KLEE.

Test Cases
Integer Overflow (CWE-190)

CWE190_Integer_Overflow__int_rand_add_45_bad.c

Vulnerability: Adding 1 to a random int may overflow.

CWE190_Integer_Overflow__char_fscanf_add_12.c

Vulnerability: Adding 1 to a char value read from the console may overflow.

Divide by Zero (CWE-369)

CWE369_Divide_by_Zero__float_connect_socket_21_bad.c

Vulnerability: Division by a float value read from a socket may be zero.

CWE369_Divide_by_Zero__int_fscanf_modulo_01_bad.c

Vulnerability: Modulo operation with an int read from console may be zero.

Building and Running

Compile with Clang/LLVM
Make sure you have KLEE installed and its include path available. Example:

clang -I /usr/lib/klee/include -emit-llvm -c -g -O0 driver_<testcase>.c -o harness.bc


Replace <testcase> with the name of your driver file.

Run with KLEE

klee harness.bc


KLEE will explore symbolic inputs and generate .ktest files for inputs that trigger assertion failures.
