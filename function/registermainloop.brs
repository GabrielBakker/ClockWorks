! function\registermainloop.brs
! Created on 10/09/2026
!
! fnRegisterMainloop - Main Loop event for REGISTER. Makes Esc do exactly what the
!   Exit button does. Without this, Esc on a screen with a file would ask whether to
!   save the record. If fnExitRegister keeps the screen open, the key is cancelled
!   the house way: reset fkey, set Function to -1, and leave ExitMode at 0.
!
! #Include {exitregister}

def fnRegisterMainloop
   if Function=99 or fkey=99 then
      let fnExitRegister
      if ExitMode=0 then
         let fkey(-1)
         let Function=-1
      end if
   end if
fnend
