! function\initinvitem.brs
! Created on 10/10/2026
!
! fnInitInvItem - Initialize event for INVEDIT (Add Item): a new item is active,
!   taxable, a clock (new clocks are added all the time; the few services are set up
!   once) and added today. Its item number is given when it's saved.
!
def fnInitInvItem
   let F$(IN_ITEMTYPE)="C"
   let F$(IN_STATUS)="A"
   let F$(IN_TAXABLE)="Y"
   let F(IN_DATEADDED)=days(date$("ccyymmdd"),"ccyymmdd")
fnend
