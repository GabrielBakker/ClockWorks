! start.br - ClockWorks main entry point  #Autonumber# 100,10
!
! Created 10/09/2026
!
! Runs the REGISTER screen, one sale at a time. Completing or voiding a sale saves
! the invoice and returns its number; fnAfterSale (printlib.brs) then offers a
! receipt for a completed sale, and we loop straight into the next sale. Exit
! returns nothing, which ends the program. If the clerk closed the window with its X
! (fkey 93), close BR entirely too.
!
   library "screenio" : fnfm$
   library "printlib" : fnAfterSale
   dim Result$*255

   do
      let Result$=fnfm$("REGISTER")
      if len(trim$(Result$)) then let fnAfterSale(trim$(Result$))
   loop while len(trim$(Result$))
   if fkey=93 then execute "System"
   stop
