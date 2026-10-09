! function\removesaleline.brs
! Created on 10/09/2026
!
! fnRemoveSaleLine - Remove Line button on SALELINES. Asks first, then deletes the
!   selected line from the sales file and refreshes the list. REGISTER's Main Loop
!   recalculates the sale's totals when the clerk returns to it.
!
dim RlSales$(1)*1024, RlSales(1)

def fnRemoveSaleLine(;___,RlSalesFile)
   if trim$(CurrentKey$)="" or trim$(F$(SL_ITEMID))="" then
      let Msgbox("Please select the line to remove first.","Remove Line","OK","INF")
   else if 2==Msgbox("Remove "&trim$(F$(SL_DESCRIPTION))&" from this sale?","Remove Line","yN","QST") then
      let RlSalesFile=fnOpen("sales",mat RlSales$,mat RlSales,mat Form$)
      read #RlSalesFile, using form$(RlSalesFile), key=CurrentKey$: mat RlSales$, mat RlSales nokey RemoveLineGone
      delete #RlSalesFile:
      RemoveLineGone: !
      let fnCloseFile(RlSalesFile,"sales")
      let RepopulateListviews=1
   end if
fnend
