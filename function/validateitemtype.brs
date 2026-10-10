! function\validateitemtype.brs
! Created on 10/10/2026
!
! fnValidateItemType - Validate event for INVEDIT's Type field. Only C (clock),
!   P (part) or S (service) are allowed; anything else returns 0, so ScreenIO puts
!   the previous value back. The field has the AEX attribute, so this runs as soon
!   as the cursor leaves it.
!
def fnValidateItemType(&FieldText$)
   let FieldText$=uprc$(trim$(FieldText$))
   if len(FieldText$)=1 and pos("CPS",FieldText$) then
      let fnValidateItemType=1
   else
      let Msgbox("Type must be C (clock), P (part) or S (service).","Type","OK","EXCL")
   end if
fnend
