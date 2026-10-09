! function\applypayment.brs
! Created on 10/09/2026
!
! fnApplyPayment - Applies the Amount on TENDER as one payment of the given method
!   (CASH, CHECK or CARD) and writes it to the payment file. Check and card payments
!   need a reference (check number or card authorization) and can't be more than the
!   balance. Cash can be more: the extra becomes change when the sale is completed.
!   Used by the Cash, Check and Card buttons.
!
! fnTenderTotals - Adds up this invoice's payments (ParentKey$ is the invoice
!   number) and fills in Paid so far and Balance Due. Also notes the last payment
!   sequence number used, for the next payment.
!
! Files are opened by fnTenderEnter (function\tenderenter.brs).
!
! #Include {tenderenter}

def fnApplyPayment(Method$;___,Amount,Balance)
   let Amount=val(S$(SIO_PAYAMOUNT)) conv ApplyBadAmount
   let fnTenderTotals
   let Balance=val(S$(SIO_TENDERBALANCE))
   if Balance<=0 then
      let Msgbox("This sale is already paid in full. Click Done, then Complete Sale.","Paid in Full","OK","INF")
   else if Amount<=0 then
      let Msgbox("Please enter the amount the customer is paying.","Amount","OK","EXCL")
   else if round(Amount,2)<>Amount then
      let Msgbox("Amounts can't have more than two decimal places.","Amount","OK","EXCL")
   else if Method$<>"CASH" and Amount>Balance then
      let Msgbox("A "&lwrc$(Method$)&" payment can't be more than the balance of "&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",Balance))&". Only cash can be more, to give change.","Amount","OK","EXCL")
   else if Method$<>"CASH" and trim$(S$(SIO_PAYREFERENCE))="" then
      if Method$="CHECK" then
         let Msgbox("Please enter the check number.","Check Number","OK","EXCL")
      else
         let Msgbox("Please enter the card authorization code.","Card Authorization","OK","EXCL")
      end if
   else
      mat TdPay$=("") : mat TdPay=(0)
      let TdPay$(PY_INVOICENO)=ParentKey$
      let TdPay(PY_SEQ)=TenderLastSeq+1
      let TdPay(PY_PAYDATE)=days(date$("ccyymmdd"),"ccyymmdd")
      let TdPay$(PY_METHOD)=Method$
      let TdPay(PY_AMOUNT)=Amount
      let TdPay$(PY_REFERENCE)=S$(SIO_PAYREFERENCE)
      write #TdPayFile, using form$(TdPayFile): mat TdPay$, mat TdPay
      let fnTenderTotals
      let S$(SIO_PAYAMOUNT)=str$(max(0,val(S$(SIO_TENDERBALANCE))))
      let S$(SIO_PAYREFERENCE)=""
      let RepopulateListviews=1
   end if
   goto ApplyDone
   ApplyBadAmount: !
   let Msgbox("Please type the amount as a number, for example 125.50.","Amount","OK","EXCL")
   ApplyDone: !
fnend

def fnTenderTotals(;___,Paid)
   let TenderLastSeq=0
   restore #TdPayFile, key>=rpad$(ParentKey$,8)&chr$(0): nokey TenderTotalsDone
   do
      read #TdPayFile, using form$(TdPayFile): mat TdPay$, mat TdPay eof TenderTotalsDone
      if TdPay$(PY_INVOICENO)<>ParentKey$ then exit do
      let Paid+=TdPay(PY_AMOUNT)
      let TenderLastSeq=max(TenderLastSeq,TdPay(PY_SEQ))
   loop
   TenderTotalsDone: !
   let S$(SIO_TENDERTOTAL)=str$(TenderTotal)
   let S$(SIO_TENDERPAID)=str$(Paid)
   let S$(SIO_TENDERBALANCE)=str$(TenderTotal-Paid)
fnend
