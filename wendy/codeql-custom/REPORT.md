# REPORT — Double Free Detection (CWE-415)

## Rule Intent
The intent of this rule is to detect **double free vulnerabilities** in C/C++ code, where the same heap-allocated pointer is freed more than once without being reassigned. 

---

## CWE Mapping
- **CWE-415: Double Free**

The detected pattern directly maps to CWE-415, which describes situations where memory is deallocated more than once. The Juliet test cases explicitly model this behavior using `malloc()` followed by multiple `free()` calls.

---

## Detection Design

### Sources
Sources represent pointers that originate from heap allocation.  
In the refined query, sources are limited to calls to:
- `malloc`
- `calloc`
- `realloc`

This ensures the rule focuses only on heap memory that is valid input to `free()`.

---

### Sinks
Sinks are calls to:
- `free(pointer)`

The rule reports when the same pointer reaches **two separate `free()` calls** without being reassigned in between.

---

### Barriers (Sanitization)
Pointer reassignment acts as a barrier.  
If a pointer is reassigned after being freed (for example, set to a new allocation or another value), tracking stops. This avoids reporting false positives where memory is intentionally reused safely.

---

## Validation
The query was tested against Juliet CWE-415 test cases. It correctly flags known bad examples where a pointer is freed twice, while the refined version avoids many good variants that should not be reported.

## Limitations
- Limited control-flow reasoning
- Does not handle wrapper free functions

## Next Steps
- Add better control-flow handling
- Treat `ptr = NULL` after `free(ptr)` as safe
- Expand detection across function boundaries
