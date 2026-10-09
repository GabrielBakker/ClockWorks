! function\completesale.brs
! Created on 10/09/2026
!
! fnCompleteSale - REGISTER's Complete Sale button. Needs items on the sale and a
!   balance of zero or less. Takes each clock and part out of inventory (quantity
!   on hand down, date last sold set; services are never stocked), records any
!   change due, marks the invoice Paid and saves it with ExitMode=SaveAndQuit.
!   start.brs then opens the register again for the next sale.
!
! #Include {additemtosale}

def fnCompleteSale(;___,ItemQty,LastLine,Change)
   if F$(IV_STATUS)<>"O" then
      let Msgbox("There's no sale in progress to complete.","Complete Sale","OK","INF")
      goto CompleteDone
   end if
   let fnTotalSale("",ItemQty,LastLine)
   if LastLine=0 then
      let Msgbox("This sale has no items on it. Ring something up, or exit.","Complete Sale","OK","INF")
      goto CompleteDone
   end if
   if F(IV_AMTPAID)<F(IV_TOTAL) then
      let Msgbox("There is still "&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",F(IV_TOTAL)-F(IV_AMTPAID)))&" due. Use Pay to take the rest of the payment first.","Balance Due","OK","EXCL")
      goto CompleteDone
   end if

   let fnTakeOutOfStock
   let Change=F(IV_AMTPAID)-F(IV_TOTAL)
   let F(IV_CHANGEDUE)=Change
   let F$(IV_STATUS)="P"
   if Change>0 then
      let Msgbox("Change due:  $"&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",Change)),"Change Due","OK","INF")
   end if
   let ExitMode=SaveAndQuit
   CompleteDone: !
fnend

! Lowers quantity on hand and sets the date last sold for every clock and part on
! the sale. Services are skipped.
def fnTakeOutOfStock
   restore #SalesFile, key>=rpad$(F$(IV_INVOICENO),8)&chr$(0)&chr$(0): nokey StockDone
   do
      read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof StockDone
      if Sales$(SL_INVOICENO)<>F$(IV_INVOICENO) then exit do
      read #InvFile, using form$(InvFile), key=fnKey$(InvFile,Sales$(SL_ITEMID)), reserve: mat Inv$, mat Inv nokey StockNextLine
      if Inv$(IN_ITEMTYPE)<>"S" then
         let Inv(IN_QTYONHAND)-=Sales(SL_QTY)
         let Inv(IN_LASTSOLD)=F(IV_INVDATE)
         rewrite #InvFile, using form$(InvFile): mat Inv$, mat Inv
      end if
      release #InvFile:
      StockNextLine: !
   loop
   StockDone: !
fnend
