! function\validatebuyitem.brs
! Created on 10/10/2026
!
! fnValidateBuyItem - Validate event for BUY's "Restock item #" box. Blank means a
!   new item. Otherwise the item must exist and be a clock or a part (services
!   can't be purchased); its description and stock show beside the box. Returns 0
!   to make ScreenIO put back what was there before.
!
! #Include {buyenter}

def fnValidateBuyItem(&FieldText$)
   let FieldText$=uprc$(trim$(FieldText$))
   let S$(SIO_BUYITEMDESC)=""
   if FieldText$="" then
      let fnValidateBuyItem=1
      goto ValidateBuyItemDone
   end if
   if len(FieldText$)>8 then goto ValidateBuyItemNotFound
   read #ByInvFile, using form$(ByInvFile), key=fnKey$(ByInvFile,FieldText$): mat ByInv$, mat ByInv nokey ValidateBuyItemNotFound
   if ByInv$(IN_ITEMTYPE)="S" then
      let Msgbox(trim$(ByInv$(IN_DESCRIPTION))&" is a service. Only clocks and parts can be purchased.","Can't Purchase a Service","OK","EXCL")
   else
      let S$(SIO_BUYITEMDESC)=trim$(ByInv$(IN_DESCRIPTION))&"  (on hand: "&str$(ByInv(IN_QTYONHAND))&")"
      let fnValidateBuyItem=1
   end if
   goto ValidateBuyItemDone
   ValidateBuyItemNotFound: !
   let Msgbox("There's no item "&FieldText$&" in the inventory. Leave the box blank to buy a new item, or use the magnifier to pick one.","Item Not Found","OK","EXCL")
   ValidateBuyItemDone: !
fnend
