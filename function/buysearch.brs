! function\buysearch.brs
! Created on 10/10/2026
!
! fnBuySearch - Click event for BUY's magnifier. Shows ITEMSEARCH in restock mode
!   (ParentKey$ "RESTOCK": every active clock and part, even those out of stock) and
!   passes the chosen item through the box's own Validate function.
!
! #Include {validatebuyitem}

def fnBuySearch(;___,ItemId$*255)
   let ItemId$=fnfm$("ITEMSEARCH","",0,0,"RESTOCK")
   if len(trim$(ItemId$)) then
      if fnValidateBuyItem(ItemId$) then let S$(SIO_BUYITEMID)=ItemId$
   end if
fnend
