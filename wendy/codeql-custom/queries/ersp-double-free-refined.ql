/**
 * @name Refined Double Free
 * @description Detects heap-allocated pointers freed twice without reassignment.
 * @kind problem
 * @problem.severity error
 * @id ersp/cpp/double-free-refined-v3
 */

 import cpp
 import semmle.code.cpp.dataflow.new.DataFlow
 
 /** Heap allocation calls */
 class AllocationCall extends FunctionCall {
   AllocationCall() {
     this.getTarget().hasName(["malloc", "calloc", "realloc"])
   }
 }
 
 /** free() calls */
 class FreeCall extends FunctionCall {
   FreeCall() {
     this.getTarget().hasName("free")
   }
 
   Expr getFreedExpr() { result = this.getArgument(0) }
 }
 
 /** Data-flow configuration */
 module DoubleFreeConfig implements DataFlow::ConfigSig {
 
   /** SOURCE: pointer freed that originates from heap allocation */
   predicate isSource(DataFlow::Node source) {
     exists(FreeCall f, AllocationCall alloc |
       source.asExpr() = f.getFreedExpr() and
       DataFlow::localFlow(
         DataFlow::exprNode(alloc),
         DataFlow::exprNode(f.getFreedExpr())
       )
     )
   }
 
   /** SINK: a later free of the same pointer */
   predicate isSink(DataFlow::Node sink) {
     exists(FreeCall f |
       sink.asExpr() = f.getFreedExpr()
     )
   }
 
   /** BARRIER: pointer reassignment */
   predicate isBarrier(DataFlow::Node node) {
     exists(Assignment a |
       a.getLValue() = node.asExpr()
     )
   }
 }
 
 module DoubleFreeTracking = DataFlow::Global<DoubleFreeConfig>;
 
 from FreeCall firstFree, FreeCall secondFree,
      DataFlow::Node source, DataFlow::Node sink
 where
   source.asExpr() = firstFree.getFreedExpr() and
   sink.asExpr() = secondFree.getFreedExpr() and
   DoubleFreeTracking::flow(source, sink) and
   firstFree != secondFree and
   firstFree.getLocation().getStartLine() <
     secondFree.getLocation().getStartLine()
 select
   secondFree,
   "Double Free: Pointer was freed earlier at line $@ and not reassigned.",
   firstFree,
   firstFree.getLocation().getStartLine().toString()
 