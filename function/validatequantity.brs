! function\validatequantity.brs
! Created on 10/10/2026
!
! fnValidateQuantity - Validate event for a quantity bought: a whole number, more
!   than zero. Returns 0 otherwise, so ScreenIO puts the previous value back.
!
def fnValidateQuantity(&FieldText$;___,Number)
   let Number=val(srep$(FieldText$,",","")) conv QuantityBad
   if Number<=0 or int(Number)<>Number then goto QuantityBad
   let fnValidateQuantity=1
   goto QuantityDone
   QuantityBad: !
   let Msgbox("Please enter a whole number, more than zero.","Quantity","OK","EXCL")
   QuantityDone: !
fnend
