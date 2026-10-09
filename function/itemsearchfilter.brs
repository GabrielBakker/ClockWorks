! function\itemsearchfilter.brs
! Created on 10/09/2026
!
! fnItemSearchFilter$ - Filter for the ITEMSEARCH listview: shows only items that can
!   be sold right now. That's active items that are in stock, plus active services,
!   which are never stocked.
!
def fnItemSearchFilter$
   if F$(IN_STATUS)="A" and (F$(IN_ITEMTYPE)="S" or F(IN_QTYONHAND)>0) then
      let fnItemSearchFilter$="1"
   else
      let fnItemSearchFilter$=""
   end if
fnend
