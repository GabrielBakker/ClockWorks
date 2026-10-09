! function\registermainloop.brs
! Created on 10/09/2026
!
! fnRegisterMainloop - Main Loop event for REGISTER. When the clerk tries to leave
!   (Exit button, or the window's close X) while a sale has items on it, asks whether
!   to abandon the sale. Yes removes its lines from the sales file and quits; No keeps
!   the register open.
!
!   ScreenIO's own AskSaveAndQuit can't do this: it doesn't know the sale's lines are
!   already in the sales file. And it has to be Main Loop: Main Loop runs after a
!   button has set ExitMode, so it can still cancel the exit, while the screen's Exit
!   event runs only once leaving is final. A cancelled key is reset the house way:
!   fkey(-1) unless the window was closed (93), Function=-1 and ExitMode=0.
!
! fnAbandonSale - Deletes the current invoice's lines, and hands its invoice number
!   back if no later sale has taken a number since.
!
!   While a sale is open it also re-totals the sale on every pass, so the totals
!   follow any line changed or removed inside SALELINES (Change Qty, Remove Line).
!
! #Include {registerenter}
! #Include {additemtosale}

def fnRegisterMainloop(;___,ItemQty,LastLine)
   if F$(IV_STATUS)="O" then let fnTotalSale("",ItemQty,LastLine)
   if ExitMode and F$(IV_STATUS)="O" then
      if 2==Msgbox("This sale has items on it. Are you sure you want to quit? They will be removed from the sale.","Quit This Sale?","yN","QST") then
         let fnAbandonSale
         let ExitMode=QuitOnly
      else
         if fkey<>93 then let fkey(-1)
         let Function=-1
         let ExitMode=0
      end if
   end if
fnend

def fnAbandonSale(;___,InvoiceNo$*8)
   let InvoiceNo$=F$(IV_INVOICENO)
   restore #SalesFile, key>=rpad$(InvoiceNo$,8)&chr$(0)&chr$(0): nokey AbandonLinesDone
   do
      read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof AbandonLinesDone
      if Sales$(SL_INVOICENO)<>InvoiceNo$ then exit do
      delete #SalesFile:
   loop
   AbandonLinesDone: !

   read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec AbandonNumberDone
   if Cfg(CF_NEXTINVOICE)=val(InvoiceNo$)+1 then
      let Cfg(CF_NEXTINVOICE)-=1
      rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
   end if
   release #CfgFile:
   AbandonNumberDone: !
fnend
