! function\writeinvitem.brs
! Created on 10/10/2026
!
! fnWriteInvItem - Write event for INVEDIT, just before ScreenIO saves the item. A new
!   item (no item number yet) gets the next number for its type: CLKnnnn for a
!   clock, PRTnnnn for a part, SVCnnnn for a service. Inventory is opened OutIn for
!   the lookup, like every other open of it in this session (error 0608 otherwise).
!
! #Include {nextinvid}

dim WiInv$(1)*1024, WiInv(1)

def fnWriteInvItem(;___,WiInvFile,Prefix$*3)
   if trim$(F$(IN_ITEMID))="" then
      if F$(IN_ITEMTYPE)="C" then
         let Prefix$="CLK"
      else if F$(IN_ITEMTYPE)="P" then
         let Prefix$="PRT"
      else
         let Prefix$="SVC"
      end if
      let WiInvFile=fnOpen("inventory",mat WiInv$,mat WiInv,mat Form$)
      let F$(IN_ITEMID)=fnNextInvId$(WiInvFile,Prefix$)
      let fnCloseFile(WiInvFile,"inventory")
   end if
fnend
