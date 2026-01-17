/**
 * @name Potential double-free vulnerability
 * @description Detects when allocated memory may be freed multiple times.
 * @kind problem
 * @problem.severity error
 * @id ersp/cpp/double-free
 * @tags security
 *       external/cwe/cwe-415
 */

import cpp

// v1 - simple variable tracking

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

from FreeCall free1, FreeCall free2, Variable v
where
  free1.getFreedExpr() = v.getAnAccess() and
  free2.getFreedExpr() = v.getAnAccess() and
  free1 != free2 and
  free1.getLocation().getStartLine() < free2.getLocation().getStartLine()
select free2, "Potential double-free: variable $@ was already freed $@.", 
  v, v.getName(),
  free1, "here"
