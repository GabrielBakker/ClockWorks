! function\nextinvid.brs
! Created on 10/10/2026
!
! fnNextInvId$ - The next free item number with a given prefix (CLK, PRT or SVC),
!   read from the inventory file open on InvFile: the highest number in use plus one,
!   as in CLK0013. Shared by BUY (new items bought) and INVEDIT (items added there).
!
dim NxInv$(1)*1024, NxInv(1)

def fnNextInvId$*8(InvFile,Prefix$*3;___,Highest)
   restore #InvFile, key>=fnKey$(InvFile,Prefix$): nokey NextInvIdDone
   do
      read #InvFile, using form$(InvFile): mat NxInv$, mat NxInv eof NextInvIdDone
      if NxInv$(IN_ITEMID)(1:3)<>Prefix$ then exit do
      let Highest=max(Highest,val(trim$(NxInv$(IN_ITEMID)(4:8)))) conv NextInvIdSkip
      NextInvIdSkip: !
   loop
   NextInvIdDone: !
   let fnNextInvId$=Prefix$&lpad$(str$(Highest+1),4,"0")
fnend
