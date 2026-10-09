! function\dayreport.brs
! Created on 10/09/2026
!
! fnDayReport - REGISTER's Day Report button. Prints today's end of day report
!   (printlib.brs) to a print preview, from which it can be printed.
!
def fnDayReport
   library "printlib" : fnPrintDayReport
   let fnPrintDayReport(days(date$("ccyymmdd"),"ccyymmdd"))
fnend
