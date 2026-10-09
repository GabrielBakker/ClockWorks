! function\searchinventory.brs
! Created on 10/09/2026
!
! fnSearchInventory - Click event for REGISTER's magnifier picture (its search
!   button). Shows the ITEMSEARCH list of items (Enter selects one) and passes the
!   chosen item number through the item box's own Validate function, exactly as if
!   it had been typed, so it is rung up the same way and the box is left blank.
!
! #Include {additemtosale}

def fnSearchInventory(;___,ItemId$*255)
   let ItemId$=fnfm$("ITEMSEARCH")
   if len(trim$(ItemId$)) then let fnAddItemToSale(ItemId$)
fnend
