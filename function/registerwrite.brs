! function\registerwrite.brs
! Created on 10/10/2026
!
! fnRegisterWrite - Write event for REGISTER. Runs whenever REGISTER is about to save
!   its invoice: after Complete Sale or Void Sale (status P or V), which save as
!   usual, and also when the clerk clicks the other tab, which ScreenIO treats as
!   Save-and-quit.
!   - No sale in progress: nothing to save, so just leave (QuitOnly). Without this a
!     tab switch would write an empty invoice record.
!   - A sale in progress: with payments taken it can't be dropped; otherwise ask, and
!     Yes abandons it (fnAbandonSale) and leaves.
!   - To stay, set ExitMode=0 and leave fkey alone: when it is still 92 (a tab
!     click), ScreenIO switches the tab back itself. fkey(-1) here would stop that.
!
! #Include {registermainloop}

def fnRegisterWrite
   if F$(IV_STATUS)="P" or F$(IV_STATUS)="V" then goto RegisterWriteDone
   if F$(IV_STATUS)<>"O" then
      let ExitMode=QuitOnly
   else if F(IV_AMTPAID)>0 then
      let Msgbox("Payments have been taken on this sale, so it can't just be dropped. Please complete it or void it.","Sale in Progress","OK","EXCL")
      let ExitMode=0
   else if 2==Msgbox("This sale has items on it. Are you sure you want to leave it? They will be removed from the sale.","Leave This Sale?","yN","QST") then
      let fnAbandonSale
      let ExitMode=QuitOnly
   else
      let ExitMode=0
   end if
   RegisterWriteDone: !
fnend
