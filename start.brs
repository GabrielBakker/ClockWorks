! start.br - ClockWorks main entry point  #Autonumber# 100,10
!
! Created 10/09/2026
!
! Opens the two ClockWorks tabs through ScreenIO's run.brs: Sales (the REGISTER) and
! Purchases (buying stock). run.brs reruns a tab's screen whenever it exits, so the
! register simply starts the next sale after each one is completed or voided.
! Esc is blocked; the app is left by closing the window with its X (fkey 93),
! which closes BR entirely too.
!
   library "run" : fnRunTabs
   dim Screen$(2)*18, Caption$(2)*20

   let Screen$(1)="REGISTER" : let Caption$(1)="Sales"
   let Screen$(2)="PURCHASES" : let Caption$(2)="Purchases"
   !            Screens      Captions      Rows Cols Inside Predraw Msg  Row Col Start BlockESC ExitOnCancel
   let fnRunTabs(mat Screen$,mat Caption$,0,   0,   0,     0,      "",  0,  0,  1,    1,       0)
   if fkey=93 then execute "System"
   stop
