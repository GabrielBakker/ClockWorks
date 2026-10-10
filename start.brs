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

   ! The main window must be at least 2 rows and 2 columns bigger than the tabs, which
   ! open at row 2, column 2 and take the largest tab screen's size (24 x 96), or the
   ! tabs fail to open with error 0630.
   open #0: "rows=27,cols=100, N=/#FFFFFF:#3C2614",display,outin

   let Screen$(1)="REGISTER" : let Caption$(1)="Sales"
   let Screen$(2)="PURCHASES" : let Caption$(2)="Purchases"
   !            Screens      Captions      Rows Cols Inside Predraw Msg  Row Col Start BlockESC ExitOnCancel
   let fnRunTabs(mat Screen$,mat Caption$,0,   0,   0,     0,      "",  0,  0,  1,    1,       0)
   if fkey=93 then execute "System"
   stop
