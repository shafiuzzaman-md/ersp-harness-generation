/**
 * @name Potential double-free vulnerability
 * @description Detects when allocated memory may be freed multiple times.
 * @kind path-problem
 * @problem.severity error
 * @id ersp/cpp/double-free
 * @tags security
 *       external/cwe/cwe-415
 */

import cpp
private import semmle.code.cpp.dataflow.new.DataFlow::DataFlow as DataFlow
private import semmle.code.cpp.dataflow.new.TaintTracking::TaintTracking as TaintTracking

//Target functions
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

//Source
module DoubleFreeConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    src.asExpr() instanceof MallocCall
  }

//Sink
  predicate isSink(DataFlow::Node snk) {
    exists(FreeCall fc |
      snk.asExpr() = fc.getFreedExpr()
    )
  }
}

module DoubleFreeFlow = DataFlow::Global<DoubleFreeConfig>;

import DoubleFreeFlow::PathGraph

//Select
from DoubleFreeFlow::PathNode src, DoubleFreeFlow::PathNode snk, FreeCall fc
where
  DoubleFreeFlow::flowPath(src, snk) and
  snk.getNode().asExpr() = fc.getFreedExpr()
select
  fc,
  src, snk,
  "Memory allocated here may be freed multiple times."
