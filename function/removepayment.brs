! function\removepayment.brs
! Created on 10/09/2026
!
! fnRemovePayment - TENDER's Remove Payment button, for a payment entered by
!   mistake. Asks first, then deletes the selected payment and updates the totals.
!
! #Include {applypayment}

def fnRemovePayment
   if trim$(CurrentKey$)="" or trim$(F$(PY_METHOD))="" then
      let Msgbox("Please select the payment to remove first.","Remove Payment","OK","INF")
   else if 2==Msgbox("Remove the "&lwrc$(trim$(F$(PY_METHOD)))&" payment of "&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",F(PY_AMOUNT)))&"?","Remove Payment","yN","QST") then
      read #TdPayFile, using form$(TdPayFile), key=CurrentKey$: mat TdPay$, mat TdPay nokey RemovePaymentGone
      delete #TdPayFile:
      RemovePaymentGone: !
      let fnTenderTotals
      let S$(SIO_PAYAMOUNT)=str$(max(0,val(S$(SIO_TENDERBALANCE))))
      let RepopulateListviews=1
   end if
fnend
