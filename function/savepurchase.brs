! function\savepurchase.brs
! Created on 10/10/2026
!
! fnSavePurchase - BUY's Save button. Every field checks its own value as it's typed
!   (its Validate function). What's left is what a single field can't check: a
!   Validate only runs when the field changes, so a required field never touched is
!   still blank; and a new item needs a description and a retail price while a
!   restock doesn't. When it's complete, ExitMode=SaveAndQuit runs the Write event
!   (fnWritePurchase) and saves.
!
def fnSavePurchase
   if trim$(F$(PU_SOURCE))="" then
      let Msgbox("Who did we buy it from? Please fill in Bought From.","Bought From","OK","EXCL")
   else if trim$(S$(SIO_BUYITEMID))<>"" then
      let ExitMode=SaveAndQuit
   else if trim$(S$(SIO_NEWDESC))="" then
      let Msgbox("Please give the new item a description, or fill in Restock Item # to add to an item we already have.","New Item","OK","EXCL")
   else if val(S$(SIO_NEWPRICE))<=0 then
      let Msgbox("Please give the new item a retail price.","New Item","OK","EXCL")
   else
      let ExitMode=SaveAndQuit
   end if
fnend
