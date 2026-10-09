! function\additemtosale.brs
! Created on 10/09/2026
!
! fnAddItemToSale - Validate event for REGISTER's "Item # / UPC" box. Rings up
!   whatever was typed or scanned, then clears the box for the next item. A
!   quantity can go in front with an asterisk: 1.5*SVC0004 is an hour and a half of
!   labor, 3*PRT0001 is three clock keys. Also called by the magnifier's search.
!
! fnRingUpItem - Splits off the quantity, looks the item up by item number, then by
!   UPC, and checks it can be sold (fnSaleQtyOk). On the first item of a sale it
!   starts the invoice. Then it writes the sales line, updates the totals, and asks
!   ScreenIO to redraw SALELINES. Nothing is redrawn when the item can't be added.
!
! fnTotalSale - Reads the current sale's lines: totals them into the invoice and
!   Balance Due, and reports how many of one item are on the sale and the last line
!   number used.
!
! Files are opened by fnRegisterEnter (function\registerenter.brs).
!
! #Include {registerenter}
! #Include {saleqtyrules}

def fnAddItemToSale(&FieldText$)
   if len(trim$(FieldText$)) then
      let fnRingUpItem(FieldText$)
      let FieldText$=""
   end if
   let fnAddItemToSale=1
fnend

def fnRingUpItem(Entry$*255;___,ItemQty,LastLine,Qty,Star)
   let Entry$=uprc$(trim$(Entry$))
   let Qty=1
   let Star=pos(Entry$,"*")
   if Star then
      let Qty=val(Entry$(1:Star-1)) conv RingUpBadQty
      let Entry$=trim$(Entry$(Star+1:len(Entry$)))
   end if
   mat Inv$=("") : mat Inv=(0)

   if len(Entry$)>8 then goto RingUpTryUpc
   read #InvFile, using form$(InvFile), key=fnKey$(InvFile,Entry$): mat Inv$, mat Inv nokey RingUpTryUpc
   goto RingUpFound
   RingUpTryUpc: !
   if len(Entry$)>14 then goto RingUpNotFound
   read #InvUpcFile, using form$(InvUpcFile), key=fnKey$(InvUpcFile,Entry$): mat Inv$, mat Inv nokey RingUpNotFound
   goto RingUpFound
   RingUpNotFound: !
   let Msgbox("I couldn't find """&Entry$&""" in the inventory, either as an item number or as a UPC. Please check it and try again, or use Search.","Item Not Found","OK","EXCL")
   goto RingUpDone

   RingUpFound: !
   if Inv$(IN_STATUS)<>"A" then
      let Msgbox(trim$(Inv$(IN_DESCRIPTION))&" ("&trim$(Inv$(IN_ITEMID))&") isn't available for sale right now.","Not Available","OK","EXCL")
      goto RingUpDone
   end if

   let fnTotalSale(Inv$(IN_ITEMID),ItemQty,LastLine)
   if ~fnSaleQtyOk(Inv$(IN_ITEMTYPE),Qty,Inv(IN_QTYONHAND),ItemQty,Inv$(IN_DESCRIPTION)) then goto RingUpDone

   if trim$(F$(IV_INVOICENO))="" then
      if ~fnStartInvoice then goto RingUpDone
   end if

   mat Sales$=("") : mat Sales=(0)
   let Sales$(SL_INVOICENO)=F$(IV_INVOICENO)
   let Sales(SL_LINENO)=LastLine+1
   let Sales$(SL_ITEMID)=Inv$(IN_ITEMID)
   let Sales$(SL_DESCRIPTION)=Inv$(IN_DESCRIPTION)
   let Sales(SL_QTY)=Qty
   let Sales(SL_UNITPRICE)=Inv(IN_PRICE)
   let Sales(SL_EXTENDED)=round(Inv(IN_PRICE)*Qty,2)
   let Sales$(SL_TAXABLE)=Inv$(IN_TAXABLE)
   let Sales(SL_SALEDATE)=F(IV_INVDATE)
   write #SalesFile, using form$(SalesFile): mat Sales$, mat Sales

   let fnTotalSale(Inv$(IN_ITEMID),ItemQty,LastLine)
   let RedrawScreens=1
   let fnRingUpItem=1
   goto RingUpDone
   RingUpBadQty: !
   let Msgbox("I couldn't read the quantity in front of the *. Type it like this: 1.5*SVC0004","Quantity","OK","EXCL")
   RingUpDone: !
fnend

! Takes the next invoice number from the store settings and fills in the new
! invoice's header fields. Returns 0 if the store settings record is missing.
def fnStartInvoice
   read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec StartInvoiceNoConfig
   let F$(IV_INVOICENO)=lpad$(str$(Cfg(CF_NEXTINVOICE)),8,"0")
   let Cfg(CF_NEXTINVOICE)+=1
   rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
   release #CfgFile:
   let F(IV_INVDATE)=days(date$("ccyymmdd"),"ccyymmdd")
   let F$(IV_INVTIME)=time$
   let F$(IV_CLERK)=login_name$
   let F$(IV_STATUS)="O"
   let F(IV_TAXRATE)=Cfg(CF_TAXRATE)
   let fnStartInvoice=1
   goto StartInvoiceDone
   StartInvoiceNoConfig: !
   let Msgbox("The store settings record is missing, so I can't number the invoice. Run seeddata to create it.","Store Settings Missing","OK","ERR")
   StartInvoiceDone: !
fnend

def fnTotalSale(ItemId$*8,&ItemQty,&LastLine;___,Subtotal,Taxable)
   let ItemQty=LastLine=0
   if trim$(F$(IV_INVOICENO))="" then goto TotalSaleDone
   restore #SalesFile, key>=rpad$(F$(IV_INVOICENO),8)&chr$(0)&chr$(0): nokey TotalSaleDone
   do
      read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof TotalSaleDone
      if Sales$(SL_INVOICENO)<>F$(IV_INVOICENO) then exit do
      let Subtotal+=Sales(SL_EXTENDED)
      if Sales$(SL_TAXABLE)="Y" then let Taxable+=Sales(SL_EXTENDED)
      if Sales$(SL_ITEMID)=ItemId$ then let ItemQty+=Sales(SL_QTY)
      let LastLine=max(LastLine,Sales(SL_LINENO))
   loop
   TotalSaleDone: !
   let F(IV_SUBTOTAL)=Subtotal
   let F(IV_TAXAMT)=round(Taxable*F(IV_TAXRATE),2)
   let F(IV_TOTAL)=Subtotal-F(IV_DISCOUNT)+F(IV_TAXAMT)
   let S$(SIO_BALANCEDUE)=str$(F(IV_TOTAL)-F(IV_AMTPAID))
fnend
