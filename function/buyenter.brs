! function\buyenter.brs
! Created on 10/10/2026
!
! fnBuyEnter - Enter event for BUY (New Purchase). Opens inventory and the store
!   settings; fnBuyExit closes them. Inventory is opened OutIn, like every other open
!   of it in this session (BR error 0608 otherwise).
!
dim ByInv$(1)*1024, ByInv(1), ByInvFile
dim ByCfg$(1)*1024, ByCfg(1), ByCfgFile

def fnBuyEnter(mat Form$)
   let ByInvFile=fnOpen("inventory",mat ByInv$,mat ByInv,mat Form$)
   let ByCfgFile=fnOpen("storecfg",mat ByCfg$,mat ByCfg,mat Form$)
fnend
