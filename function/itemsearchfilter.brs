! function\itemsearchfilter.brs
! Created on 10/09/2026
!
! fnItemSearchFilter$ - Filter for the ITEMSEARCH listview.
!   Selling (the register's magnifier): only items that can be sold right now, that
!     is active items in stock, plus active services, which are never stocked.
!   Restocking (BUY's magnifier passes ParentKey$ "RESTOCK"): every active clock and
!     part, including ones with none left; services can't be purchased.
!
def fnItemSearchFilter$
   if trim$(ParentKey$)="RESTOCK" then
      if F$(IN_STATUS)="A" and F$(IN_ITEMTYPE)<>"S" then let fnItemSearchFilter$="1"
   else
      if F$(IN_STATUS)="A" and (F$(IN_ITEMTYPE)="S" or F(IN_QTYONHAND)>0) then let fnItemSearchFilter$="1"
   end if
fnend
