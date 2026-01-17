/**
 * @name Potential buffer over-read
 * @description Tainted length used in buffer read operations
 * @kind path-problem
 * @problem.severity warning
 * @id ersp/cpp/cwe-126-buffer-overread
 * @tags security
 *       external/cwe/cwe-126
 */

import cpp
import semmle.code.cpp.dataflow.new.DataFlow
import semmle.code.cpp.dataflow.new.TaintTracking
import Flow::PathGraph

/**
 * Functions that read from buffers using a length argument
 */
class BufferReadCall extends FunctionCall {
  BufferReadCall() {
    this.getTarget().getName().matches("memcpy|memmove|memcmp|read|recv")
  }

  Expr getLengthArg() {
    result = this.getArgument(2)
  }
}

/**
 * Dataflow configuration
 */
module OverreadConfig implements DataFlow::ConfigSig {

  /**
   * Length comes from an unconstrained source
   */
  predicate isSource(DataFlow::Node source) {
    exists(Parameter p |
      source.asExpr() = p.getAnAccess()
    )
  }

  /**
   * Length is used in a buffer read operation
   */
  predicate isSink(DataFlow::Node sink) {
    exists(BufferReadCall call |
      sink.asExpr() = call.getLengthArg()
    )
  }
}

module Flow = TaintTracking::Global<OverreadConfig>;

from Flow::PathNode source, Flow::PathNode sink
where Flow::flowPath(source, sink)
select sink.getNode(),
       source,
       sink,
       "Potential buffer over-read: length is derived from an unconstrained source."

