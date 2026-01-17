/**
 * @name Potential OOB via tainted memcpy length
 * @description Flags memcpy calls where the length argument is tainted.
 * @kind problem
 * @problem.severity warning
 * @id ersp/cpp/oob-memcpy-tainted-length
 */

 import cpp
 import semmle.code.cpp.dataflow.new.TaintTracking
 
 class MemcpyCall extends FunctionCall {
   MemcpyCall() {
     this.getTarget().hasName("memcpy")
   }
   Expr getLen() { result = this.getArgument(2) }
 }
 
 module MemcpyTaintConfig implements DataFlow::ConfigSig {
   predicate isSource(DataFlow::Node source) {
     exists(Parameter p | source.asParameter() = p)
   }
 
   predicate isSink(DataFlow::Node sink) {
     exists(MemcpyCall c | sink.asExpr() = c.getLen())
   }
 }
 
 module MemcpyTaintTracking = TaintTracking::Global<MemcpyTaintConfig>;
 
 from DataFlow::Node source, DataFlow::Node sink, MemcpyCall c
 where
   MemcpyTaintTracking::flow(source, sink) and
   c.getLen() = sink.asExpr()
 select
   c, "Potential out-of-bounds: memcpy length derived from untrusted input."