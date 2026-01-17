## Reproducibility

The following steps were used to generate the CodeQL database and baseline results using the Juliet Test Suite (CWE-415).

```bash
python3 juliet.py 415 -g -m
```

```bash
codeql database create db-415 --language=cpp --command="make j2"
```
```bash
codeql database analyze db-415 codeql/cpp-queries \
  --format=sarif-latest --output=baseline.sarif
```

## Refinement Notes

### Goal of Refinement
The goal of refining the original query was to reduce false positives while still catching real double-free bugs in the Juliet CWE-415 test cases. The first version was intentionally simple but very noisy. The refined version adds basic data-flow reasoning to better model how double frees actually happen.

---

### Before vs After Summary

- **v1 (ersp-double-free.ql)**  
  - Findings: **~200**
  - Behavior: Flags any two `free()` calls on the same variable inside the same function.
  - Issue: Reports many cases that are not real double frees (for example, when the pointer is reassigned or when the code is intentionally structured for good variants).

- **v2 (ersp-double-free-refined.ql)**  
  - Findings: **~120**
  - Behavior: Tracks heap-allocated pointers, ensures the same pointer flows to two `free()` calls, and stops tracking if the pointer is reassigned.
  - Improvement: Removes a large class of false positives while keeping true CWE-415 cases.

---

### Examples of Improved Findings

1. **Pointer reassigned between frees (removed)**  
   In v1, cases where a pointer is freed, then reassigned, then freed again were incorrectly flagged.  
   In v2, reassignment acts as a barrier, so these cases are no longer reported.

2. **Good Juliet variants (more targeted)**  
   In files like `CWE415_Double_Free__malloc_free_char_03.c`, v1 flagged both the `goodB2G` and `goodG2B` functions even when the second free never executes.  
   v2 is more precise and focuses on paths where a pointer is actually freed twice without being reset.

3. **Non-heap pointers (removed)**  
   v1 did not check whether the freed pointer came from `malloc`-style allocation.  
   v2 limits sources to heap allocation calls (`malloc`, `calloc`, `realloc`), reducing noise from unrelated `free()` usage.

---

### Summary
The refined query trades some completeness for much better precision. It still detects clear double-free patterns in the Juliet bad cases, but avoids flagging many safe or intentionally fixed examples.

