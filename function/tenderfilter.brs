! function\tenderfilter.brs
! Created on 10/09/2026
!
! fnTenderFilter$ - Filter for TENDER's list of payments: shows only the payments
!   for the sale in progress, whose invoice number REGISTER passed as ParentKey$.
!
def fnTenderFilter$
   if len(trim$(ParentKey$)) and F$(PY_INVOICENO)=ParentKey$ then
      let fnTenderFilter$="1"
   else
      let fnTenderFilter$=""
   end if
fnend
