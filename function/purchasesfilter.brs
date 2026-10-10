! function\purchasesfilter.brs
! Created on 10/10/2026
!
! fnPurchasesFilter$ - Filter for the PURCHASES list. Shows every purchase, and
!   fills the Description column by looking the item up in inventory.
!
! fnInit_PurchasesFilter / fnFinal_PurchasesFilter - ScreenIO runs these once before
!   and after the list is filled, so inventory is opened once per refresh, not once
!   per row. It is opened OutIn, like every other open of inventory in this session
!   (BR error 0608 otherwise).
!
dim PfInv$(1)*1024, PfInv(1), PfInvFile

def fnPurchasesFilter$
   let S$(SIO_ITEMDESC)=""
   if PfInvFile then
      read #PfInvFile, using form$(PfInvFile), key=fnKey$(PfInvFile,F$(PU_ITEMID)): mat PfInv$, mat PfInv nokey PurchasesFilterNoItem
      let S$(SIO_ITEMDESC)=PfInv$(IN_DESCRIPTION)
   end if
   PurchasesFilterNoItem: !
   let fnPurchasesFilter$="1"
fnend

def fnInit_PurchasesFilter
   let PfInvFile=fnOpen("inventory",mat PfInv$,mat PfInv,mat Form$)
fnend

def fnFinal_PurchasesFilter
   if PfInvFile then
      let fnCloseFile(PfInvFile,"inventory")
      let PfInvFile=0
   end if
fnend
