! function\buyinit.brs
! Created on 10/10/2026
!
! fnBuyInit - Initialize event for BUY (New Purchase): the starting values for a new
!   purchase. It's dated today, for one item; a new item is a clock (what the store
!   buys most) and taxable (its check box starts checked) unless the clerk says
!   otherwise.
!
def fnBuyInit
   let F(PU_PURCHDATE)=days(date$("ccyymmdd"),"ccyymmdd")
   let F(PU_QTY)=1
   let S$(SIO_NEWTYPE)="C"
   let S$(SIO_NEWTAXABLE)="Y"
fnend
