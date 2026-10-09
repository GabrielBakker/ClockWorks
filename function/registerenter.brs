! function\registerenter.brs
! Created on 10/09/2026
!
! fnRegisterEnter - Enter event for REGISTER. Opens the files the register's
!   functions use while a sale is rung up. fnRegisterExit closes them again.
!
dim Inv$(1)*1024, Inv(1), InvFile, InvUpcFile
dim Sales$(1)*1024, Sales(1), SalesFile
dim Cfg$(1)*1024, Cfg(1), CfgFile

def fnRegisterEnter(mat Form$)
   let InvFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$,1)
   let InvUpcFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$,1,4)
   let SalesFile=fnOpen("sales",mat Sales$,mat Sales,mat Form$)
   let CfgFile=fnOpen("storecfg",mat Cfg$,mat Cfg,mat Form$)
fnend
