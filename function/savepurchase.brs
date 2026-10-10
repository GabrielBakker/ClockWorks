! function\savepurchase.brs
! Created on 10/10/2026
!
! fnSavePurchase - BUY's Save button. Checks the purchase before anything is
!   written; only when it's complete does it set ExitMode=SaveAndQuit, which runs
!   the Write event (fnWritePurchase) and saves the purchase.
!
def fnSavePurchase
   if trim$(F$(PU_SOURCE))="" then
      let Msgbox("Who did we buy it from? Please fill in Bought From.","Bought From","OK","EXCL")
   else if F(PU_QTY)<=0 or int(F(PU_QTY))<>F(PU_QTY) then
      let Msgbox("The quantity has to be a whole number, more than zero.","Quantity","OK","EXCL")
   else if F(PU_UNITCOST)<0 then
      let Msgbox("The unit cost can't be negative.","Unit Cost","OK","EXCL")
   else if trim$(S$(SIO_BUYITEMID))<>"" then
      let ExitMode=SaveAndQuit
   else if uprc$(trim$(S$(SIO_NEWTYPE)))<>"C" and uprc$(trim$(S$(SIO_NEWTYPE)))<>"P" then
      let Msgbox("For a new item, the Type must be C (clock) or P (part). Or fill in Restock item # to add to an item we already have.","New Item","OK","EXCL")
   else if trim$(S$(SIO_NEWDESC))="" then
      let Msgbox("Please give the new item a description.","New Item","OK","EXCL")
   else if val(S$(SIO_NEWPRICE))<=0 then
      let Msgbox("Please give the new item a retail price.","New Item","OK","EXCL")
   else
      let ExitMode=SaveAndQuit
   end if
fnend
