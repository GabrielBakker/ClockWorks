! function\buyexit.brs
! Created on 10/10/2026
!
! fnBuyExit - Exit event for BUY. Closes the files fnBuyEnter opened.
!
def fnBuyExit
   if ByInvFile then
      let fnCloseFile(ByInvFile,"inventory")
      let ByInvFile=0
   end if
   if ByCfgFile then
      let fnCloseFile(ByCfgFile,"storecfg")
      let ByCfgFile=0
   end if
fnend
