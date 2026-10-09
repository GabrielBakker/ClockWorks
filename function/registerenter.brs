! function\registerenter.brs
! Created on 10/09/2026
!
! fnRegisterEnter - Enter event for REGISTER. Opens the files the register's
!   functions use while a sale is rung up. fnRegisterExit closes them again.
!
!   Inventory is opened OutIn, not input-only, even for lookups: ITEMSEARCH (opened
!   from the Search button) binds to inventory, and a ScreenIO screen opens its file
!   OutIn. BR refuses an OutIn open of a file this session already has open for
!   input (error 0608), so the OutIn open must come first.
!
dim Inv$(1)*1024, Inv(1), InvFile, InvUpcFile
dim Sales$(1)*1024, Sales(1), SalesFile
dim Cfg$(1)*1024, Cfg(1), CfgFile
dim Pay$(1)*1024, Pay(1), PayFile

def fnRegisterEnter(mat Form$)
   let InvFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$)
   let InvUpcFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$,0,4)
   let SalesFile=fnOpen("sales",mat Sales$,mat Sales,mat Form$)
   let CfgFile=fnOpen("storecfg",mat Cfg$,mat Cfg,mat Form$)
   let PayFile=fnOpen("payment",mat Pay$,mat Pay,mat Form$)
fnend
