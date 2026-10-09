! function\saleqtyrules.brs
! Created on 10/09/2026
!
! fnSaleQtyOk - The rules for a quantity on a sales line, shared by the item box
!   (REGISTER) and Change Qty (QTYEDIT). Returns 1 if Qty is allowed; otherwise
!   explains why in a Msgbox and returns 0.
!
!   ItemType$     C=Clock, P=Part, S=Service (from the inventory record)
!   Qty           the quantity wanted on this line
!   OnHand        inventory quantity on hand (ignored for services, never stocked)
!   OtherQty      how many of this item are already on the sale on other lines
!   Description$  the item's description, for the messages
!
def fnSaleQtyOk(ItemType$,Qty,OnHand,OtherQty,Description$*60)
   if Qty<=0 then
      let Msgbox("The quantity has to be more than zero.","Quantity","OK","EXCL")
   else if Qty>999.99 then
      let Msgbox("The largest quantity a line can hold is 999.99.","Quantity","OK","EXCL")
   else if round(Qty,2)<>Qty then
      let Msgbox("Quantities can have at most two decimal places, for example 1.25 hours.","Quantity","OK","EXCL")
   else if ItemType$<>"S" and int(Qty)<>Qty then
      let Msgbox(trim$(Description$)&" is sold in whole numbers. Only labor and other services can have a fraction.","Quantity","OK","EXCL")
   else if ItemType$<>"S" and OtherQty+Qty>OnHand then
      if OnHand=1 then
         let Msgbox(trim$(Description$)&" is one of a kind, and it's already on this sale.","Already on the Sale","OK","EXCL")
      else
         let Msgbox("We only have "&str$(OnHand)&" of "&trim$(Description$)&" in stock, and "&str$(OtherQty)&" of them are already on this sale.","Not Enough Stock","OK","EXCL")
      end if
   else
      let fnSaleQtyOk=1
   end if
fnend
