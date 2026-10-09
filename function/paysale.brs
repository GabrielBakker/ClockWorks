! function\paysale.brs
! Created on 10/09/2026
!
! fnPaySale - REGISTER's Pay button. Opens TENDER to take payments for the sale in
!   progress. The invoice header isn't saved until the sale is completed or voided,
!   so TENDER gets the invoice number as ParentKey$ and the sale total in
!   PassedData$(1). REGISTER's Main Loop re-totals "Paid so far" from the payment
!   file when the clerk comes back.
!
! #Include {additemtosale}

dim TenderData$(1)*255

def fnPaySale(;___,Ret$*255,ItemQty,LastLine)
   if F$(IV_STATUS)<>"O" then
      let Msgbox("There's nothing to pay for yet. Ring up some items first.","Pay","OK","INF")
   else if F(IV_TOTAL)-F(IV_AMTPAID)<=0 then
      let Msgbox("This sale is already paid in full. Click Complete Sale to finish it.","Pay","OK","INF")
   else
      mat TenderData$(1)
      let TenderData$(1)=str$(F(IV_TOTAL))
      let Ret$=fnfm$("TENDER","",0,0,F$(IV_INVOICENO),0,0,0,0,mat TenderData$)
      let fnTotalSale("",ItemQty,LastLine)
   end if
fnend
