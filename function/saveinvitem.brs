! function\saveinvitem.brs
! Created on 10/10/2026
!
! fnSaveInvItem - INVEDIT's Save button. Every field checks its own value as it's
!   typed (its Validate function), so all that's left here is what a field can't check
!   for itself: a Validate only runs when the field changes, so a new item whose
!   Description was never touched would otherwise be saved blank. Services are never
!   stocked, so their On Hand is kept at 0. Then ExitMode=SaveAndQuit runs the Write
!   event (fnWriteInvItem) and saves.
!
def fnSaveInvItem
   if trim$(F$(IN_DESCRIPTION))="" then
      let Msgbox("Please give the item a description.","Description","OK","EXCL")
   else
      if F$(IN_ITEMTYPE)="S" then let F(IN_QTYONHAND)=0
      let ExitMode=SaveAndQuit
   end if
fnend
