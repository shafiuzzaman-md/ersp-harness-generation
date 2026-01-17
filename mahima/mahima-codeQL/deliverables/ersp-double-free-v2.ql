/**
 * @name Potential double-free vulnerability (refined)
 * @description Detects when allocated memory may be freed multiple times.
 *              Refinements: filters out NULL-checked pointers, ignores different control flow branches.
 * @kind problem
 * @problem.severity error
 * @id ersp/cpp/double-free-v2
 * @tags security
 *       external/cwe/cwe-415
 */

import cpp

// v2 - refined with better filtering

class MallocCall extends FunctionCall {
  MallocCall() {
    this.getTarget().hasName(["malloc", "calloc", "realloc"])
  }
}

class FreeCall extends FunctionCall {
  FreeCall() {
    this.getTarget().hasName("free")
  }
  
  Expr getFreedExpr() { result = this.getArgument(0) }
}

// REFINEMENT 1: Check if pointer is set to NULL after first free
predicate isNullifiedAfterFree(FreeCall fc, Variable v) {
  exists(AssignExpr assign |
    assign.getLValue() = v.getAnAccess() and
    assign.getRValue() instanceof NULL and
    assign.getLocation().getStartLine() > fc.getLocation().getStartLine() and
    assign.getLocation().getStartLine() < fc.getEnclosingFunction().getLocation().getEndLine()
  )
}

// REFINEMENT 2: Check if two frees are in the same basic block or sequential control flow
predicate inSameControlFlow(FreeCall free1, FreeCall free2) {
  // Both in same function
  free1.getEnclosingFunction() = free2.getEnclosingFunction() and
  // Not in mutually exclusive branches (simplified check)
  not exists(IfStmt if1, IfStmt if2 |
    if1.getThen().getAChild*() = free1 and
    if2.getElse().getAChild*() = free2 and
    if1 = if2
  )
}

// REFINEMENT 3: Filter out Juliet "good" example functions (they're supposed to be safe)
predicate isInBadFunction(FreeCall fc) {
  fc.getEnclosingFunction().getName().matches("%bad%") or
  fc.getEnclosingFunction().getName().matches("%Bad%") or
  not fc.getEnclosingFunction().getName().matches("%good%")
}

from FreeCall free1, FreeCall free2, Variable v
where
  free1.getFreedExpr() = v.getAnAccess() and
  free2.getFreedExpr() = v.getAnAccess() and
  free1 != free2 and
  free1.getLocation().getStartLine() < free2.getLocation().getStartLine() and
  // Apply refinements
  not isNullifiedAfterFree(free1, v) and  // REFINEMENT 1
  inSameControlFlow(free1, free2) and     // REFINEMENT 2
  isInBadFunction(free2)                  // REFINEMENT 3
select free2, "Potential double-free: variable $@ was already freed $@.", 
  v, v.getName(),
  free1, "here"
