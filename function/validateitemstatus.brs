! function\validateitemstatus.brs
! Created on 10/10/2026
!
! fnValidateItemStatus - Validate event for INVEDIT's Status field. Only A (active),
!   H (on hold) or I (inactive) are allowed; anything else returns 0, so ScreenIO
!   puts the previous value back. The field has the AEX attribute, so this runs as
!   soon as the cursor leaves it.
!
def fnValidateItemStatus(&FieldText$)
   let FieldText$=uprc$(trim$(FieldText$))
   if len(FieldText$)=1 and pos("AHI",FieldText$) then
      let fnValidateItemStatus=1
   else
      let Msgbox("Status must be A (active), H (on hold) or I (inactive).","Status","OK","EXCL")
   end if
fnend
