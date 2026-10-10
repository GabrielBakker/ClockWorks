! function\validatenotnegative.brs
! Created on 10/10/2026
!
! fnValidateNotNegative - Validate event for an amount (a price or cost): it must be
!   a number, zero or more. The text may carry the field's PIC formatting, such as
!   1,234.50, so commas are ignored. Returns 0 otherwise, so ScreenIO puts the
!   previous value back.
!
def fnValidateNotNegative(&FieldText$;___,Amount)
   let Amount=val(srep$(FieldText$,",","")) conv NotNegativeBad
   if Amount<0 then goto NotNegativeBad
   let fnValidateNotNegative=1
   goto NotNegativeDone
   NotNegativeBad: !
   let Msgbox("Please enter an amount of zero or more, for example 125.50.","Amount","OK","EXCL")
   NotNegativeDone: !
fnend
