! function\buyinit.brs
! Created on 10/10/2026
!
! fnBuyInit - Initialize event for BUY: a new purchase is dated today, one of it,
!   and a new item is taxable unless the clerk says otherwise.
!
def fnBuyInit
   let F(PU_PURCHDATE)=days(date$("ccyymmdd"),"ccyymmdd")
   let F(PU_QTY)=1
   let S$(SIO_NEWTAXABLE)="Y"
fnend
