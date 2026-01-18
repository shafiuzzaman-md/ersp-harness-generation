/**
 * @name Buffer over-read in memmove
 * @description Detects memmove where size is calculated from destination instead of source.
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id cpp/memmove-buffer-overread
 * @tags security
 *       external/cwe/cwe-126
 */

import cpp

from FunctionCall memmove, Expr dest, Expr source, Expr size, FunctionCall sizeFunc
where
  // Find memmove calls and get dest, source and size -- look for size depending on dest not source.
  memmove.getTarget().getName() in ["memmove", "wmemmove"] and
  dest = memmove.getArgument(0) and
  source = memmove.getArgument(1) and
  size = memmove.getArgument(2) and
  
  // Check if size uses strlen/wcslen depending on dest
  sizeFunc.getTarget().getName() in ["strlen", "wcslen", "strnlen", "wcsnlen"] and
  sizeFunc.getParent*() = size and
  
  sizeFunc.getArgument(0).(VariableAccess).getTarget() = 
    dest.(VariableAccess).getTarget() and  
  dest.(VariableAccess).getTarget() != source.(VariableAccess).getTarget()
  
select memmove, 
  "memmove may read beyond source buffer: size is calculated from destination instead of source"