! function\validatebuytype.brs
! Created on 10/10/2026
!
! fnValidateBuyType - Validate event for the New Purchase screen's Type field. Only
!   C (clock) or P (part) can be bought; services can't. Returns 0 for anything else,
!   so ScreenIO puts the previous value back. The field has the AEX attribute, so
!   this runs as soon as the cursor leaves it.
!
def fnValidateBuyType(&FieldText$)
   let FieldText$=uprc$(trim$(FieldText$))
   if len(FieldText$)=1 and pos("CP",FieldText$) then
      let fnValidateBuyType=1
   else
      let Msgbox("Type must be C (clock) or P (part). Services can't be purchased.","Type","OK","EXCL")
   end if
fnend
