! function\validatesaleqty.brs
! Created on 10/09/2026
!
! fnValidateSaleQty - Validate event for QTYEDIT's Quantity field (Change Qty on a
!   sales line). Applies the same rules as the item box (fnSaleQtyOk), counting
!   this item's other lines on the same sale. Returns 1 to accept the new quantity,
!   or 0, which makes ScreenIO put the old quantity back.
!
!   Inventory is opened OutIn even though it is only read here: REGISTER already has
!   it open OutIn, and every open of a file in one session must match (error 0608).
!
! #Include {saleqtyrules}

dim QeInv$(1)*1024, QeInv(1), QeSales$(1)*1024, QeSales(1)

def fnValidateSaleQty(&FieldText$;___,Qty,OtherQty,QeInvFile,QeSalesFile)
   let Qty=val(FieldText$) conv ValidateQtyBad
   let QeInvFile=fnOpen("inventory",mat QeInv$,mat QeInv,mat Form$)
   read #QeInvFile, using form$(QeInvFile), key=fnKey$(QeInvFile,F$(SL_ITEMID)): mat QeInv$, mat QeInv nokey ValidateQtyNoItem

   let QeSalesFile=fnOpen("sales",mat QeSales$,mat QeSales,mat Form$)
   restore #QeSalesFile, key>=rpad$(F$(SL_INVOICENO),8)&chr$(0)&chr$(0): nokey ValidateQtyCounted
   do
      read #QeSalesFile, using form$(QeSalesFile): mat QeSales$, mat QeSales eof ValidateQtyCounted
      if QeSales$(SL_INVOICENO)<>F$(SL_INVOICENO) then exit do
      if QeSales$(SL_ITEMID)=F$(SL_ITEMID) and QeSales(SL_LINENO)<>F(SL_LINENO) then let OtherQty+=QeSales(SL_QTY)
   loop
   ValidateQtyCounted: !
   let fnCloseFile(QeSalesFile,"sales")

   let fnValidateSaleQty=fnSaleQtyOk(QeInv$(IN_ITEMTYPE),Qty,QeInv(IN_QTYONHAND),OtherQty,QeInv$(IN_DESCRIPTION))
   goto ValidateQtyClose
   ValidateQtyNoItem: !
   let Msgbox("I couldn't find item "&trim$(F$(SL_ITEMID))&" in the inventory any more, so I can't check this quantity.","Item Not Found","OK","EXCL")
   ValidateQtyClose: !
   let fnCloseFile(QeInvFile,"inventory")
   goto ValidateQtyDone
   ValidateQtyBad: !
   let Msgbox("Please type the quantity as a number, for example 2 or 1.5.","Quantity","OK","EXCL")
   ValidateQtyDone: !
fnend
