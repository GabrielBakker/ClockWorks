! function\salelinesfilter.brs
! Created on 10/09/2026
!
! fnSaleLinesFilter$ - Filter for the SALELINES listview: shows only the lines of the
!   sale in progress. REGISTER passes its invoice number in as ParentKey$ (through the
!   SALELINES screen control's function text). Before the first item is rung up there
!   is no invoice number yet, so nothing shows.
!
def fnSaleLinesFilter$
   if len(trim$(ParentKey$)) and trim$(f$(sl_invoiceno))=trim$(ParentKey$) then
      let fnSaleLinesFilter$="1"
   else
      let fnSaleLinesFilter$=""
   end if
fnend
