/**
 * @name Super Broad Audit
 * @description Flags printf, syslog, AND Juliet's printLine helper.
 * @kind problem
 * @problem.severity warning
 * @id ersp/super-broad-audit
 */

import cpp

from FunctionCall call
where
  // 1. Standard C print functions
  call.getTarget().getName().matches("%printf")
  or
  // 2. Syslog
  call.getTarget().getName() = "syslog"
  or
  // 3. Juliet's internal helper (Guaranteed to exist in every file)
  call.getTarget().getName() = "printLine"

select call, "AUDIT: Found a printing function: " + call.getTarget().getName()
