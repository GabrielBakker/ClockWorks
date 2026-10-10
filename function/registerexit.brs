! function\registerexit.brs
! Created on 10/09/2026
!
! fnRegisterExit - Exit event for REGISTER. When a sale has just been completed, offers
!   its receipt (printlib's fnAfterSale): ScreenIO has already saved the invoice by the
!   time the Exit event runs. Then closes the files fnRegisterEnter opened.
!
!   On the Sales tab, run.brs reopens REGISTER for the next sale as soon as it exits.
!
def fnRegisterExit
   if ExitMode=SaveAndQuit and F$(IV_STATUS)="P" then
      library "printlib" : fnAfterSale
      let fnAfterSale(F$(IV_INVOICENO))
   end if
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
