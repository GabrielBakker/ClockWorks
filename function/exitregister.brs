! function\exitregister.brs
! Created on 10/09/2026
!
! fnExitRegister - REGISTER's Exit button (and Esc, through fnRegisterMainloop).
!   Won't leave while a sale has items on it, because its lines are already in the
!   sales file and need a completed or voided invoice to go with them.
!
def fnExitRegister
   if len(trim$(F$(IV_INVOICENO))) then
      let Msgbox("This sale has items on it. Please complete it or void it before you exit.","Sale in Progress","OK","EXCL")
      let ExitMode=0
   else
      let ExitMode=QuitOnly
   end if
fnend
