! function\validatewholenumber.brs
! Created on 10/10/2026
!
! fnValidateWholeNumber - Validate event for a count that can be zero: a whole
!   number, zero or more (On Hand, Most per Sale). Returns 0 otherwise, so ScreenIO
!   puts the previous value back.
!
def fnValidateWholeNumber(&FieldText$;___,Number)
   let Number=val(srep$(FieldText$,",","")) conv WholeNumberBad
   if Number<0 or int(Number)<>Number then goto WholeNumberBad
   let fnValidateWholeNumber=1
   goto WholeNumberDone
   WholeNumberBad: !
   let Msgbox("Please enter a whole number, zero or more.","Whole Number","OK","EXCL")
   WholeNumberDone: !
fnend
