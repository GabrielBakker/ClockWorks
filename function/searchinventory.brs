! function\searchinventory.brs
! Created on 10/09/2026
!
! fnSearchInventory - REGISTER's Search button. Opens the ITEMSEARCH picker and rings
!   up the item the clerk selects, through the same code as the item box.
!
! #Include {additemtosale}

def fnSearchInventory(;___,ItemId$*255)
   let ItemId$=fnfm$("ITEMSEARCH")
   if len(trim$(ItemId$)) then let fnRingUpItem(ItemId$)
fnend
