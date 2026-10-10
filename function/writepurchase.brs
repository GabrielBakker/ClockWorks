! function\writepurchase.brs
! Created on 10/10/2026
!
! fnWritePurchase - Write event for BUY. Runs just before ScreenIO saves the
!   purchase (fnSavePurchase has already checked it). Gives the purchase the next
!   purchase number from the store settings and works out its total, then updates
!   inventory: a restock adds the quantity and takes the latest unit cost; a new
!   item gets the next item number for its type (CLKnnnn or PRTnnnn) and is added.
!
! fnNextItemId$ - The next free item number with a given prefix.
!
! #Include {buyenter}

def fnWritePurchase(;___,ItemId$*8,Prefix$*3)
   read #ByCfgFile, using form$(ByCfgFile), rec=1, reserve: mat ByCfg$, mat ByCfg norec WritePurchaseNoConfig
   let F$(PU_PURCHASEID)="P"&lpad$(str$(ByCfg(CF_NEXTPURCHASE)),7,"0")
   let ByCfg(CF_NEXTPURCHASE)+=1
   rewrite #ByCfgFile, using form$(ByCfgFile): mat ByCfg$, mat ByCfg
   release #ByCfgFile:
   WritePurchaseNoConfig: !
   let F(PU_TOTALCOST)=round(F(PU_UNITCOST)*F(PU_QTY),2)

   if trim$(S$(SIO_BUYITEMID))<>"" then
      let ItemId$=uprc$(trim$(S$(SIO_BUYITEMID)))
      read #ByInvFile, using form$(ByInvFile), key=fnKey$(ByInvFile,ItemId$), reserve: mat ByInv$, mat ByInv nokey WritePurchaseDone
      let ByInv(IN_QTYONHAND)+=F(PU_QTY)
      let ByInv(IN_COST)=F(PU_UNITCOST)
      rewrite #ByInvFile, using form$(ByInvFile): mat ByInv$, mat ByInv
      release #ByInvFile:
   else
      if uprc$(trim$(S$(SIO_NEWTYPE)))="C" then
         let Prefix$="CLK"
      else
         let Prefix$="PRT"
      end if
      let ItemId$=fnNextItemId$(Prefix$)
      mat ByInv$=("") : mat ByInv=(0)
      let ByInv$(IN_ITEMID)=ItemId$
      let ByInv$(IN_UPC)=S$(SIO_NEWUPC)
      let ByInv$(IN_ITEMTYPE)=uprc$(trim$(S$(SIO_NEWTYPE)))
      let ByInv$(IN_DESCRIPTION)=S$(SIO_NEWDESC)
      let ByInv$(IN_CATEGORY)=S$(SIO_NEWCATEGORY)
      let ByInv$(IN_MAKER)=S$(SIO_NEWMAKER)
      let ByInv$(IN_ORIGIN)=S$(SIO_NEWORIGIN)
      let ByInv$(IN_ERA)=S$(SIO_NEWERA)
      let ByInv$(IN_CONDITION)=S$(SIO_NEWCONDITION)
      let ByInv$(IN_SERIALNO)=S$(SIO_NEWSERIAL)
      let ByInv$(IN_LOCATION)=S$(SIO_NEWLOCATION)
      let ByInv(IN_COST)=F(PU_UNITCOST)
      let ByInv(IN_PRICE)=val(S$(SIO_NEWPRICE))
      let ByInv(IN_QTYONHAND)=F(PU_QTY)
      let ByInv$(IN_TAXABLE)=uprc$(trim$(S$(SIO_NEWTAXABLE)))
      if ByInv$(IN_TAXABLE)<>"N" then let ByInv$(IN_TAXABLE)="Y"
      let ByInv$(IN_STATUS)="A"
      let ByInv(IN_DATEADDED)=F(PU_PURCHDATE)
      let ByInv$(IN_NOTES)=F$(PU_NOTES)
      write #ByInvFile, using form$(ByInvFile): mat ByInv$, mat ByInv
   end if
   let F$(PU_ITEMID)=ItemId$
   WritePurchaseDone: !
fnend

def fnNextItemId$*8(Prefix$*3;___,Highest)
   restore #ByInvFile, key>=fnKey$(ByInvFile,Prefix$): nokey NextItemIdDone
   do
      read #ByInvFile, using form$(ByInvFile): mat ByInv$, mat ByInv eof NextItemIdDone
      if ByInv$(IN_ITEMID)(1:3)<>Prefix$ then exit do
      let Highest=max(Highest,val(trim$(ByInv$(IN_ITEMID)(4:8)))) conv NextItemIdSkip
      NextItemIdSkip: !
   loop
   NextItemIdDone: !
   let fnNextItemId$=Prefix$&lpad$(str$(Highest+1),4,"0")
fnend
