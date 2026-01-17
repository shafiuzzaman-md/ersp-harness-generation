/**
 * @name Double Free
 * @description- Flags instances where a pointer is freed twice.
 * @kind problem
 * @problem.severity error
 * @id ersp/cpp/double-free
 * @tags security
 * external/cwe/cwe-415
 */

 import cpp

 from FunctionCall f1, FunctionCall f2, VariableAccess va1, VariableAccess va2
 where
   // Look for two calls to free
   f1.getTarget().hasName("free") and
   f2.getTarget().hasName("free") and
   f1 != f2 and
   
   // Get the variables being freed
   va1 = f1.getArgument(0) and
   va2 = f2.getArgument(0) and
   
   // Only flag if they are the SAME variable
   va1.getTarget() = va2.getTarget() and
   
   // Only look within the same function
   f1.getEnclosingFunction() = f2.getEnclosingFunction()
 select f2, "Double Free: Variable '" + va1.getTarget().getName() + "' appears in two free() calls."