! function\voidsale.brs
! Created on 10/09/2026
!
! fnVoidSale - REGISTER's Void Sale button. After the clerk confirms, marks the
!   invoice Void and saves it with ExitMode=SaveAndQuit, so its lines and any
!   payments stay on record as the audit trail. No inventory was changed, so
!   there is nothing to put back. start.brs then opens the register again.
!
def fnVoidSale(;___,Question$*400)
   if F$(IV_STATUS)<>"O" then
      let Msgbox("There's no sale in progress to void.","Void Sale","OK","INF")
   else
      let Question$="Void this sale? It will be kept on record as void."
      if F(IV_AMTPAID)>0 then
         let Question$(inf:0)=" The customer has paid "&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",F(IV_AMTPAID)))&". Please give that back to them."
      end if
      if 2==Msgbox(Question$,"Void Sale","yN","QST") then
         let F$(IV_STATUS)="V"
         let ExitMode=SaveAndQuit
      end if
   end if
fnend
