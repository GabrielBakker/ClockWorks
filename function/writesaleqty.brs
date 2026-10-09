! function\writesaleqty.brs
! Created on 10/09/2026
!
! fnWriteSaleQty - Write event for QTYEDIT. Runs just before ScreenIO saves the
!   sales line, and recomputes the line's amount for its new quantity.
!
def fnWriteSaleQty
   let F(SL_EXTENDED)=round(F(SL_UNITPRICE)*F(SL_QTY),2)-F(SL_DISCOUNT)
fnend
