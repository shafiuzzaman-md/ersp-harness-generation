/**
 * @name Potential OOB via tainted memcpy length
 * @description Flags memcpy calls where the length argument flows from a parameter.
 * @kind problem
 * @problem.severity warning
 * @id cpp/oob-memcpy-tainted-length
 */

import cpp
import semmle.code.cpp.dataflow.DataFlow

class MemcpyCall extends FunctionCall {
  MemcpyCall() {
    this.getTarget().hasName("memcpy") and
    this.getNumberOfArguments() >= 3
  }

  Expr getLen() { result = this.getArgument(2) }
}

from
  DataFlow::Node src,
  DataFlow::Node snk,
  MemcpyCall c
where
  exists(src.asParameter()) and
  snk.asExpr() = c.getLen() and
  DataFlow::localFlow(src, snk)
select
  c,
  "memcpy length argument may be influenced by function input."

