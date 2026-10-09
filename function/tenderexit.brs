! function\tenderexit.brs
! Created on 10/09/2026
!
! fnTenderExit - Exit event for TENDER. Closes the payment file fnTenderEnter opened.
!
def fnTenderExit
   if TdPayFile then
      let fnCloseFile(TdPayFile,"payment")
      let TdPayFile=0
   end if
fnend
