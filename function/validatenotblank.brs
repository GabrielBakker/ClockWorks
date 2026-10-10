! function\validatenotblank.brs
! Created on 10/10/2026
!
! fnValidateNotBlank - Validate event for any field that must be filled in. Returns 0
!   for a blank entry, so ScreenIO puts the previous value back.
!
def fnValidateNotBlank(&FieldText$)
   if trim$(FieldText$)="" then
      let Msgbox("This field can't be left blank.","Required","OK","EXCL")
   else
      let fnValidateNotBlank=1
   end if
fnend
