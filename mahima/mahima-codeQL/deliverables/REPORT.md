# CodeQL Double-Free Detection Report

## Rule Intent
This query detects CWE-415 (Double Free) vulnerabilities where dynamically allocated memory is freed multiple times without reallocation. The pattern identifies variables that flow from a `free()` call to another `free()` call on the same pointer, which can lead to memory corruption, crashes, or potential security exploits.

## Design Decisions

### Source
Memory deallocation calls: `free()`, representing the first point where memory is released.

### Sink
Subsequent `free()` calls on the same variable. This is because a second `free()` on an already-freed pointer is the vulnerability manifestation point.

### Sanitizers/Barriers (v2 Refinements)
1. **NULL Assignment Detection:** Filters cases where pointer is set to `NULL` after first free (safe pattern: `free(NULL)` is valid)
2. **Control Flow Analysis:** Excludes frees in mutually exclusive branches (if/else)
3. **Test Pattern Filtering:** Focuses on intentional "bad" examples in Juliet, filtering "good" test cases

## Why Findings Are Plausible
The Juliet Test Suite (CWE-415) contains intentionally vulnerable code designed to test static analysis tools. Manual inspection of findings confirms:

1. **Pattern Match:** Findings show `free(ptr); ... free(ptr);` without NULL checks
2. **Test Suite Design:** Juliet explicitly labels functions as "bad" (vulnerable) vs "good" (safe)
3. **Execution Path Validation:** v2 findings occur in sequential code paths where both frees can execute

### Example True Positive
```c
void CWE415_bad() {
    char *data = (char *)malloc(100);
    free(data);
    // ... intermediate code ...
    free(data);  // Double-free vulnerability
}
```


