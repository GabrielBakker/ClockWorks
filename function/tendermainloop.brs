! function\tendermainloop.brs
! Created on 10/09/2026
!
! fnTenderMainloop - Main Loop event for TENDER. TENDER has a listview, so ScreenIO
!   treats Enter as "select and quit" - pressing Enter after typing an amount would
!   close the screen without taking the payment. This cancels Enter the house way:
!   fkey(-1), Function=-1, ExitMode=0. Payments are taken with the Cash, Check and
!   Card buttons, and the screen is closed with Done.
!
def fnTenderMainloop
   if Function=0 and ExitMode then
      let fkey(-1)
      let Function=-1
      let ExitMode=0
   end if
fnend
