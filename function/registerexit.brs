! function\registerexit.brs
! Created on 10/09/2026
!
! fnRegisterExit - Exit event for REGISTER. Closes the files fnRegisterEnter opened.
!
def fnRegisterExit
   if InvFile then
      let fnCloseFile(InvFile,"inventory")
      let InvFile=0
   end if
   if InvUpcFile then
      let fnCloseFile(InvUpcFile,"inventory")
      let InvUpcFile=0
   end if
   if SalesFile then
      let fnCloseFile(SalesFile,"sales")
      let SalesFile=0
   end if
   if PayFile then
      let fnCloseFile(PayFile,"payment")
      let PayFile=0
   end if
   if CfgFile then
      let fnCloseFile(CfgFile,"storecfg")
      let CfgFile=0
   end if
fnend
