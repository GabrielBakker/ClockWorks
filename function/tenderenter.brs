! function\tenderenter.brs
! Created on 10/09/2026
!
! fnTenderEnter - Enter event for TENDER. Opens the payment file for writing new
!   payments, takes the sale total REGISTER passed in PassedData$(1), and fills in
!   Total, Paid so far, Balance Due and the starting Amount.
!
! #Include {applypayment}

dim TdPay$(1)*1024, TdPay(1), TdPayFile, TenderTotal, TenderLastSeq

def fnTenderEnter(mat Form$,mat PassedData$)
   let TdPayFile=fnOpen("payment",mat TdPay$,mat TdPay,mat Form$)
   let TenderTotal=0
   if udim(mat PassedData$) then let TenderTotal=val(PassedData$(1)) conv TenderEnterTotals
   TenderEnterTotals: !
   let fnTenderTotals
   let S$(SIO_PAYAMOUNT)=S$(SIO_TENDERBALANCE)
fnend
