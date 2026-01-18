/**
 * @name CWE-134: Non-Literal Format String
 * @description Detects calls where the format string is a variable (Critical Vulnerability).
 * @kind problem
 * @problem.severity error
 * @id ersp/format-string-pattern
 */

import cpp

from FunctionCall call, Expr formatArg
where
  // 1. Match any function like printf, fprintf, snprintf, syslog
  call.getTarget().getName().matches("%printf") and

  // 2. Identify the Format String argument position
  (
    (call.getTarget().getName() = "printf" and formatArg = call.getArgument(0)) or
    (call.getTarget().getName() = "fprintf" and formatArg = call.getArgument(1)) or
    (call.getTarget().getName() = "sprintf" and formatArg = call.getArgument(1)) or
    (call.getTarget().getName() = "snprintf" and formatArg = call.getArgument(2))
  ) and

  // 3. THE CHECK: Ensure the raw argument is NOT a string literal
  not formatArg.getUnconverted() instanceof StringLiteral

select call, "VULNERABILITY: This format string is a variable, not a fixed string."
