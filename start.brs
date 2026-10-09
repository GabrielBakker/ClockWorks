! start.br - ClockWorks main entry point  #Autonumber# 100,10
!
! Created 10/09/2026
!
! Runs the REGISTER screen, one sale at a time. Completing or voiding a sale saves
! the invoice and returns its number, so we loop straight into the next sale. Exit
! returns nothing, which ends the program.
!
   library "screenio" : fnfm$
   dim Result$*255

   do
      let Result$=fnfm$("REGISTER")
   loop while len(trim$(Result$))
   stop
