! function\saveinvitem.brs
! Created on 10/10/2026
!
! fnSaveInvItem - INVEDIT's Save button. Checks the item before anything is written;
!   only when it's right does it set ExitMode=SaveAndQuit, which runs the Write event
!   (fnWriteInvItem) and saves. Services are never stocked, so their On Hand is
!   simply kept at 0.
!
def fnSaveInvItem(;___,Type$)
   let Type$=uprc$(trim$(F$(IN_ITEMTYPE)))
   if Type$<>"C" and Type$<>"P" and Type$<>"S" then
      let Msgbox("Type must be C (clock), P (part) or S (service).","Type","OK","EXCL")
   else if trim$(F$(IN_DESCRIPTION))="" then
      let Msgbox("Please give the item a description.","Description","OK","EXCL")
   else if F(IN_PRICE)<0 or F(IN_COST)<0 then
      let Msgbox("Price and cost can't be negative.","Price","OK","EXCL")
   else if Type$<>"S" and (F(IN_QTYONHAND)<0 or int(F(IN_QTYONHAND))<>F(IN_QTYONHAND)) then
      let Msgbox("On Hand has to be a whole number, zero or more.","On Hand","OK","EXCL")
   else if F(IN_MAXPERSALE)<0 or int(F(IN_MAXPERSALE))<>F(IN_MAXPERSALE) then
      let Msgbox("Most per Sale has to be a whole number: 0 means no limit.","Most per Sale","OK","EXCL")
   else if pos("AHI",uprc$(trim$(F$(IN_STATUS))))=0 or trim$(F$(IN_STATUS))="" then
      let Msgbox("Status must be A (active), H (on hold) or I (inactive).","Status","OK","EXCL")
   else if pos("YN",uprc$(trim$(F$(IN_TAXABLE))))=0 or trim$(F$(IN_TAXABLE))="" then
      let Msgbox("Taxable must be Y or N.","Taxable","OK","EXCL")
   else
      let F$(IN_ITEMTYPE)=Type$
      if Type$="S" then let F(IN_QTYONHAND)=0
      let ExitMode=SaveAndQuit
   end if
fnend
