00010 ! screenio\register.br
00020 ! ScreenIO Generated Helper Library for REGISTER screen
00030 ! Copyright 2008 by Sage AX
00040 !
00050 ! Compiled On: 10/09/2026
00060 ! Version: 0
00070 !
00080 !
00090 !
00300 !
00310    option retain
00320    dim FileIOLinkageSet
00330    dim Ret$*255
00340    dim PassedData$(1)*255
00350    mat PassedData$(0)
00600 !
01000 Main: ! If you run me as a program, I run the register screen
01010    library "screenio" : fnfm$
01020    let Ret$=fnfm$("register","",0,0,"",0,0,0,0,mat PassedData$)
01030    if len(trim$(Ret$)) then
01040       print Ret$
01050    end if
01060    if fkey=93 then execute "system"
01070    stop
01080 !
05000 CustomFunctions: ! Lines 5000 - 70000 are Custom Functions
05001 ! ============================================================
05002 ! Imported From "function\additemtosale.brs"
05003 ! function\additemtosale.brs
05004 ! Created on 10/09/2026
05005 !
05006 ! fnAddItemToSale - Validate event for REGISTER's "Item # / UPC" box. Rings up
05007 !   whatever was typed or scanned, then clears the box for the next item. A
05008 !   quantity can go in front with an asterisk: 1.5*SVC0004 is an hour and a half of
05009 !   labor, 3*PRT0001 is three clock keys. Also called by the magnifier's search.
05010 !
05011 ! fnRingUpItem - Splits off the quantity, looks the item up by item number, then by
05012 !   UPC, and checks it can be sold (fnSaleQtyOk). On the first item of a sale it
05013 !   starts the invoice. Then it writes the sales line, updates the totals, and asks
05014 !   ScreenIO to redraw SALELINES. Nothing is redrawn when the item can't be added.
05015 !
05016 ! fnTotalSale - Reads the current sale's lines and payments: totals them into the invoice and
05017 !   Balance Due, and reports how many of one item are on the sale and the last line
05018 !   number used.
05019 !
05020 ! Files are opened by fnRegisterEnter (function\registerenter.brs).
05021 !
05022 ! #Include {registerenter}
05023 ! #Include {saleqtyrules}
05024 !
05025 def fnAddItemToSale(&FieldText$)
05026    if len(trim$(FieldText$)) then
05027       let fnRingUpItem(FieldText$)
05028       let FieldText$=""
05029    end if
05030    let fnAddItemToSale=1
05031 fnend
05032 !
05033 def fnRingUpItem(Entry$*255;___,ItemQty,LastLine,Qty,Star)
05034    let Entry$=uprc$(trim$(Entry$))
05035    let Qty=1
05036    let Star=pos(Entry$,"*")
05037    if Star then
05038       let Qty=val(Entry$(1:Star-1)) conv RingUpBadQty
05039       let Entry$=trim$(Entry$(Star+1:len(Entry$)))
05040    end if
05041    mat Inv$=("") : mat Inv=(0)
05042 !
05043    if len(Entry$)>8 then goto RingUpTryUpc
05044    read #InvFile, using form$(InvFile), key=fnKey$(InvFile,Entry$): mat Inv$, mat Inv nokey RingUpTryUpc
05045    goto RingUpFound
05046    RingUpTryUpc: !
05047    if len(Entry$)>14 then goto RingUpNotFound
05048    read #InvUpcFile, using form$(InvUpcFile), key=fnKey$(InvUpcFile,Entry$): mat Inv$, mat Inv nokey RingUpNotFound
05049    goto RingUpFound
05050    RingUpNotFound: !
05051    let Msgbox("I couldn't find """&Entry$&""" in the inventory, either as an item number or as a UPC. Please check it and try again, or use Search.","Item Not Found","OK","EXCL")
05052    goto RingUpDone
05053 !
05054    RingUpFound: !
05055    if Inv$(IN_STATUS)<>"A" then
05056       let Msgbox(trim$(Inv$(IN_DESCRIPTION))&" ("&trim$(Inv$(IN_ITEMID))&") isn't available for sale right now.","Not Available","OK","EXCL")
05057       goto RingUpDone
05058    end if
05059 !
05060    let fnTotalSale(Inv$(IN_ITEMID),ItemQty,LastLine)
05061    if ~fnSaleQtyOk(Inv$(IN_ITEMTYPE),Qty,Inv(IN_QTYONHAND),Inv(IN_MAXPERSALE),ItemQty,Inv$(IN_DESCRIPTION)) then goto RingUpDone
05062 !
05063    if trim$(F$(IV_INVOICENO))="" then
05064       if ~fnStartInvoice then goto RingUpDone
05065    end if
05066 !
05067    mat Sales$=("") : mat Sales=(0)
05068    let Sales$(SL_INVOICENO)=F$(IV_INVOICENO)
05069    let Sales(SL_LINENO)=LastLine+1
05070    let Sales$(SL_ITEMID)=Inv$(IN_ITEMID)
05071    let Sales$(SL_DESCRIPTION)=Inv$(IN_DESCRIPTION)
05072    let Sales(SL_QTY)=Qty
05073    let Sales(SL_UNITPRICE)=Inv(IN_PRICE)
05074    let Sales(SL_EXTENDED)=round(Inv(IN_PRICE)*Qty,2)
05075    let Sales$(SL_TAXABLE)=Inv$(IN_TAXABLE)
05076    let Sales(SL_SALEDATE)=F(IV_INVDATE)
05077    write #SalesFile, using form$(SalesFile): mat Sales$, mat Sales
05078 !
05079    let fnTotalSale(Inv$(IN_ITEMID),ItemQty,LastLine)
05080    let RedrawScreens=1
05081    let fnRingUpItem=1
05082    goto RingUpDone
05083    RingUpBadQty: !
05084    let Msgbox("I couldn't read the quantity in front of the *. Type it like this: 1.5*SVC0004","Quantity","OK","EXCL")
05085    RingUpDone: !
05086 fnend
05087 !
05088 ! Takes the next invoice number from the store settings and fills in the new
05089 ! invoice's header fields. Returns 0 if the store settings record is missing.
05090 def fnStartInvoice
05091    read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec StartInvoiceNoConfig
05092    let F$(IV_INVOICENO)=lpad$(str$(Cfg(CF_NEXTINVOICE)),8,"0")
05093    let Cfg(CF_NEXTINVOICE)+=1
05094    rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
05095    release #CfgFile:
05096    let F(IV_INVDATE)=days(date$("ccyymmdd"),"ccyymmdd")
05097    let F$(IV_INVTIME)=time$
05098    let F$(IV_CLERK)=login_name$
05099    let F$(IV_STATUS)="O"
05100    let F(IV_TAXRATE)=Cfg(CF_TAXRATE)
05101    let fnStartInvoice=1
05102    goto StartInvoiceDone
05103    StartInvoiceNoConfig: !
05104    let Msgbox("The store settings record is missing, so I can't number the invoice. Run seeddata to create it.","Store Settings Missing","OK","ERR")
05105    StartInvoiceDone: !
05106 fnend
05107 !
05108 def fnTotalSale(ItemId$*8,&ItemQty,&LastLine;___,Subtotal,Taxable,Paid)
05109    let ItemQty=LastLine=0
05110    if trim$(F$(IV_INVOICENO))="" then goto TotalSaleDone
05111    restore #SalesFile, key>=rpad$(F$(IV_INVOICENO),8)&chr$(0)&chr$(0): nokey TotalSaleDone
05112    do
05113       read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof TotalSaleDone
05114       if Sales$(SL_INVOICENO)<>F$(IV_INVOICENO) then exit do
05115       let Subtotal+=Sales(SL_EXTENDED)
05116       if Sales$(SL_TAXABLE)="Y" then let Taxable+=Sales(SL_EXTENDED)
05117       if Sales$(SL_ITEMID)=ItemId$ then let ItemQty+=Sales(SL_QTY)
05118       let LastLine=max(LastLine,Sales(SL_LINENO))
05119    loop
05120    TotalSaleDone: !
05121 !
05122    if trim$(F$(IV_INVOICENO))="" then goto TotalSalePaid
05123    restore #PayFile, key>=rpad$(F$(IV_INVOICENO),8)&chr$(0): nokey TotalSalePaid
05124    do
05125       read #PayFile, using form$(PayFile): mat Pay$, mat Pay eof TotalSalePaid
05126       if Pay$(PY_INVOICENO)<>F$(IV_INVOICENO) then exit do
05127       let Paid+=Pay(PY_AMOUNT)
05128    loop
05129    TotalSalePaid: !
05130 !
05131    let F(IV_SUBTOTAL)=Subtotal
05132    let F(IV_TAXAMT)=round(Taxable*F(IV_TAXRATE),2)
05133    let F(IV_TOTAL)=Subtotal-F(IV_DISCOUNT)+F(IV_TAXAMT)
05134    let F(IV_AMTPAID)=Paid
05135    let S$(SIO_BALANCEDUE)=str$(F(IV_TOTAL)-F(IV_AMTPAID))
05136 fnend
05137 !
05138 ! Imported From "function\searchinventory.brs"
05139 ! function\searchinventory.brs
05140 ! Created on 10/09/2026
05141 !
05142 ! fnSearchInventory - Click event for REGISTER's magnifier picture (its search
05143 !   button). Shows the ITEMSEARCH list of items (Enter selects one) and passes the
05144 !   chosen item number through the item box's own Validate function, exactly as if
05145 !   it had been typed, so it is rung up the same way and the box is left blank.
05146 !
05147 ! #Include {additemtosale}
05148 !
05149 def fnSearchInventory(;___,ItemId$*255)
05150    let ItemId$=fnfm$("ITEMSEARCH")
05151    if len(trim$(ItemId$)) then let fnAddItemToSale(ItemId$)
05152 fnend
05153 !
05154 ! Imported From "function\paysale.brs"
05155 ! function\paysale.brs
05156 ! Created on 10/09/2026
05157 !
05158 ! fnPaySale - REGISTER's Pay button. Opens TENDER to take payments for the sale in
05159 !   progress. The invoice header isn't saved until the sale is completed or voided,
05160 !   so TENDER gets the invoice number as ParentKey$ and the sale total in
05161 !   PassedData$(1). REGISTER's Main Loop re-totals "Paid so far" from the payment
05162 !   file when the clerk comes back.
05163 !
05164 ! #Include {additemtosale}
05165 !
05166 dim TenderData$(1)*255
05167 !
05168 def fnPaySale(;___,Ret$*255,ItemQty,LastLine)
05169    if F$(IV_STATUS)<>"O" then
05170       let Msgbox("There's nothing to pay for yet. Ring up some items first.","Pay","OK","INF")
05171    else if F(IV_TOTAL)-F(IV_AMTPAID)<=0 then
05172       let Msgbox("This sale is already paid in full. Click Complete Sale to finish it.","Pay","OK","INF")
05173    else
05174       mat TenderData$(1)
05175       let TenderData$(1)=str$(F(IV_TOTAL))
05176       let Ret$=fnfm$("TENDER","",0,0,F$(IV_INVOICENO),0,0,0,0,mat TenderData$)
05177       let fnTotalSale("",ItemQty,LastLine)
05178    end if
05179 fnend
05180 !
05181 ! Imported From "function\completesale.brs"
05182 ! function\completesale.brs
05183 ! Created on 10/09/2026
05184 !
05185 ! fnCompleteSale - REGISTER's Complete Sale button. Needs items on the sale and a
05186 !   balance of zero or less. Takes each clock and part out of inventory (quantity
05187 !   on hand down, date last sold set; services are never stocked), records any
05188 !   change due, marks the invoice Paid and saves it with ExitMode=SaveAndQuit.
05189 !   start.brs then opens the register again for the next sale.
05190 !
05191 ! #Include {additemtosale}
05192 !
05193 def fnCompleteSale(;___,ItemQty,LastLine,Change)
05194    if F$(IV_STATUS)<>"O" then
05195       let Msgbox("There's no sale in progress to complete.","Complete Sale","OK","INF")
05196       goto CompleteDone
05197    end if
05198    let fnTotalSale("",ItemQty,LastLine)
05199    if LastLine=0 then
05200       let Msgbox("This sale has no items on it. Ring something up, or exit.","Complete Sale","OK","INF")
05201       goto CompleteDone
05202    end if
05203    if F(IV_AMTPAID)<F(IV_TOTAL) then
05204       let Msgbox("There is still "&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",F(IV_TOTAL)-F(IV_AMTPAID)))&" due. Use Pay to take the rest of the payment first.","Balance Due","OK","EXCL")
05205       goto CompleteDone
05206    end if
05207 !
05208    let fnTakeOutOfStock
05209    let Change=F(IV_AMTPAID)-F(IV_TOTAL)
05210    let F(IV_CHANGEDUE)=Change
05211    let F$(IV_STATUS)="P"
05212    if Change>0 then
05213       let Msgbox("Change due:  $"&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",Change)),"Change Due","OK","INF")
05214    end if
05215    let ExitMode=SaveAndQuit
05216    CompleteDone: !
05217 fnend
05218 !
05219 ! Lowers quantity on hand and sets the date last sold for every clock and part on
05220 ! the sale. Services are skipped.
05221 def fnTakeOutOfStock
05222    restore #SalesFile, key>=rpad$(F$(IV_INVOICENO),8)&chr$(0)&chr$(0): nokey StockDone
05223    do
05224       read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof StockDone
05225       if Sales$(SL_INVOICENO)<>F$(IV_INVOICENO) then exit do
05226       read #InvFile, using form$(InvFile), key=fnKey$(InvFile,Sales$(SL_ITEMID)), reserve: mat Inv$, mat Inv nokey StockNextLine
05227       if Inv$(IN_ITEMTYPE)<>"S" then
05228          let Inv(IN_QTYONHAND)-=Sales(SL_QTY)
05229          let Inv(IN_LASTSOLD)=F(IV_INVDATE)
05230          rewrite #InvFile, using form$(InvFile): mat Inv$, mat Inv
05231       end if
05232       release #InvFile:
05233       StockNextLine: !
05234    loop
05235    StockDone: !
05236 fnend
05237 !
05238 ! Imported From "function\voidsale.brs"
05239 ! function\voidsale.brs
05240 ! Created on 10/09/2026
05241 !
05242 ! fnVoidSale - REGISTER's Void Sale button. After the clerk confirms, marks the
05243 !   invoice Void and saves it with ExitMode=SaveAndQuit, so its lines and any
05244 !   payments stay on record as the audit trail. No inventory was changed, so
05245 !   there is nothing to put back. start.brs then opens the register again.
05246 !
05247 def fnVoidSale(;___,Question$*400)
05248    if F$(IV_STATUS)<>"O" then
05249       let Msgbox("There's no sale in progress to void.","Void Sale","OK","INF")
05250    else
05251       let Question$="Void this sale? It will be kept on record as void."
05252       if F(IV_AMTPAID)>0 then
05253          let Question$(inf:0)=" The customer has paid "&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",F(IV_AMTPAID)))&". Please give that back to them."
05254       end if
05255       if 2==Msgbox(Question$,"Void Sale","yN","QST") then
05256          let F$(IV_STATUS)="V"
05257          let ExitMode=SaveAndQuit
05258       end if
05259    end if
05260 fnend
05261 !
05262 ! Imported From "function\registerenter.brs"
05263 ! function\registerenter.brs
05264 ! Created on 10/09/2026
05265 !
05266 ! fnRegisterEnter - Enter event for REGISTER. Opens the files the register's
05267 !   functions use while a sale is rung up. fnRegisterExit closes them again.
05268 !
05269 !   Inventory is opened OutIn, not input-only, even for lookups: ITEMSEARCH (opened
05270 !   from the Search button) binds to inventory, and a ScreenIO screen opens its file
05271 !   OutIn. BR refuses an OutIn open of a file this session already has open for
05272 !   input (error 0608), so the OutIn open must come first.
05273 !
05274 dim Inv$(1)*1024, Inv(1), InvFile, InvUpcFile
05275 dim Sales$(1)*1024, Sales(1), SalesFile
05276 dim Cfg$(1)*1024, Cfg(1), CfgFile
05277 dim Pay$(1)*1024, Pay(1), PayFile
05278 !
05279 def fnRegisterEnter(mat Form$)
05280    let InvFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$)
05281    let InvUpcFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$,0,4)
05282    let SalesFile=fnOpen("sales",mat Sales$,mat Sales,mat Form$)
05283    let CfgFile=fnOpen("storecfg",mat Cfg$,mat Cfg,mat Form$)
05284    let PayFile=fnOpen("payment",mat Pay$,mat Pay,mat Form$)
05285 fnend
05286 !
05287 ! Imported From "function\registermainloop.brs"
05288 ! function\registermainloop.brs
05289 ! Created on 10/09/2026
05290 !
05291 ! fnRegisterMainloop - Main Loop event for REGISTER. When the clerk tries to leave
05292 !   (Exit button, or the window's close X) while a sale has items on it, asks whether
05293 !   to abandon the sale. Yes removes its lines from the sales file and quits; No keeps
05294 !   the register open. Once a payment has been taken the sale can't be abandoned
05295 !   (the money must stay on record), so it has to be completed or voided instead.
05296 !
05297 !   ScreenIO's own AskSaveAndQuit can't do this: it doesn't know the sale's lines are
05298 !   already in the sales file. And it has to be Main Loop: Main Loop runs after a
05299 !   button has set ExitMode, so it can still cancel the exit, while the screen's Exit
05300 !   event runs only once leaving is final. A cancelled key is reset the house way:
05301 !   fkey(-1) unless the window was closed (93), Function=-1 and ExitMode=0.
05302 !
05303 ! fnAbandonSale - Deletes the current invoice's lines, and hands its invoice number
05304 !   back if no later sale has taken a number since.
05305 !
05306 !   While a sale is open it also re-totals the sale on every pass, so the totals
05307 !   follow any line changed or removed inside SALELINES (Change Qty, Remove Line).
05308 !
05309 ! #Include {registerenter}
05310 ! #Include {additemtosale}
05311 !
05312 def fnRegisterMainloop(;___,ItemQty,LastLine)
05313    if F$(IV_STATUS)="O" then let fnTotalSale("",ItemQty,LastLine)
05314    if ExitMode and F$(IV_STATUS)="O" and F(IV_AMTPAID)>0 then
05315       let Msgbox("Payments have been taken on this sale, so it can't just be dropped. Please complete it or void it.","Sale in Progress","OK","EXCL")
05316       if fkey<>93 then let fkey(-1)
05317       let Function=-1
05318       let ExitMode=0
05319    else if ExitMode and F$(IV_STATUS)="O" then
05320       if 2==Msgbox("This sale has items on it. Are you sure you want to quit? They will be removed from the sale.","Quit This Sale?","yN","QST") then
05321          let fnAbandonSale
05322          let ExitMode=QuitOnly
05323       else
05324          if fkey<>93 then let fkey(-1)
05325          let Function=-1
05326          let ExitMode=0
05327       end if
05328    end if
05329 fnend
05330 !
05331 def fnAbandonSale(;___,InvoiceNo$*8)
05332    let InvoiceNo$=F$(IV_INVOICENO)
05333    restore #SalesFile, key>=rpad$(InvoiceNo$,8)&chr$(0)&chr$(0): nokey AbandonLinesDone
05334    do
05335       read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof AbandonLinesDone
05336       if Sales$(SL_INVOICENO)<>InvoiceNo$ then exit do
05337       delete #SalesFile:
05338    loop
05339    AbandonLinesDone: !
05340 !
05341    read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec AbandonNumberDone
05342    if Cfg(CF_NEXTINVOICE)=val(InvoiceNo$)+1 then
05343       let Cfg(CF_NEXTINVOICE)-=1
05344       rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
05345    end if
05346    release #CfgFile:
05347    AbandonNumberDone: !
05348 fnend
05349 !
05350 ! Imported From "function\registerexit.brs"
05351 ! function\registerexit.brs
05352 ! Created on 10/09/2026
05353 !
05354 ! fnRegisterExit - Exit event for REGISTER. Closes the files fnRegisterEnter opened.
05355 !
05356 def fnRegisterExit
05357    if InvFile then
05358       let fnCloseFile(InvFile,"inventory")
05359       let InvFile=0
05360    end if
05361    if InvUpcFile then
05362       let fnCloseFile(InvUpcFile,"inventory")
05363       let InvUpcFile=0
05364    end if
05365    if SalesFile then
05366       let fnCloseFile(SalesFile,"sales")
05367       let SalesFile=0
05368    end if
05369    if PayFile then
05370       let fnCloseFile(PayFile,"payment")
05371       let PayFile=0
05372    end if
05373    if CfgFile then
05374       let fnCloseFile(CfgFile,"storecfg")
05375       let CfgFile=0
05376    end if
05377 fnend
05378 !
05379 ! Imported From "function\saleqtyrules.brs"
05380 ! function\saleqtyrules.brs
05381 ! Created on 10/09/2026
05382 !
05383 ! fnSaleQtyOk - The rules for a quantity on a sales line, shared by the item box
05384 !   (REGISTER) and Change Qty (QTYEDIT). Returns 1 if Qty is allowed; otherwise
05385 !   explains why in a Msgbox and returns 0.
05386 !
05387 !   ItemType$     C=Clock, P=Part, S=Service (from the inventory record)
05388 !   Qty           the quantity wanted on this line
05389 !   OnHand        inventory quantity on hand (ignored for services, never stocked)
05390 !   MaxPerSale    the most of this item one sale may have (0 means no limit), e.g. 1
05391 !                 for a service charged per job
05392 !   OtherQty      how many of this item are already on the sale on other lines
05393 !   Description$  the item's description, for the messages
05394 !
05395 def fnSaleQtyOk(ItemType$,Qty,OnHand,MaxPerSale,OtherQty,Description$*60)
05396    if Qty<=0 then
05397       let Msgbox("The quantity has to be more than zero.","Quantity","OK","EXCL")
05398    else if Qty>999.99 then
05399       let Msgbox("The largest quantity a line can hold is 999.99.","Quantity","OK","EXCL")
05400    else if round(Qty,2)<>Qty then
05401       let Msgbox("Quantities can have at most two decimal places, for example 1.25 hours.","Quantity","OK","EXCL")
05402    else if ItemType$<>"S" and int(Qty)<>Qty then
05403       let Msgbox(trim$(Description$)&" is sold in whole numbers. Only labor and other services can have a fraction.","Quantity","OK","EXCL")
05404    else if MaxPerSale and OtherQty+Qty>MaxPerSale then
05405       if MaxPerSale=1 then
05406          let Msgbox(trim$(Description$)&" is charged once per sale, and it's already on this sale.","Once per Sale","OK","EXCL")
05407       else
05408          let Msgbox("A sale can have at most "&str$(MaxPerSale)&" of "&trim$(Description$)&", and "&str$(OtherQty)&" are already on it.","Limit per Sale","OK","EXCL")
05409       end if
05410    else if ItemType$<>"S" and OtherQty+Qty>OnHand then
05411       if OnHand=1 then
05412          let Msgbox(trim$(Description$)&" is one of a kind, and it's already on this sale.","Already on the Sale","OK","EXCL")
05413       else
05414          let Msgbox("We only have "&str$(OnHand)&" of "&trim$(Description$)&" in stock, and "&str$(OtherQty)&" of them are already on this sale.","Not Enough Stock","OK","EXCL")
05415       end if
05416    else
05417       let fnSaleQtyOk=1
05418    end if
05419 fnend
05420 !
05421 !
05422 !
85000    def library fnCheckStringFunction(Function$*255)
85001    if Function$ = "{additemtosale}" then
85002       let fnCheckStringFunction = 0
85003    else if Function$ = "{searchinventory}" then
85004       let fnCheckStringFunction = 0
85005    else if Function$ = "{paysale}" then
85006       let fnCheckStringFunction = 0
85007    else if Function$ = "{completesale}" then
85008       let fnCheckStringFunction = 0
85009    else if Function$ = "{voidsale}" then
85010       let fnCheckStringFunction = 0
85011       else if Function$ = "{registerenter}" then
85012          let fnCheckStringFunction = 0
85013       else if Function$ = "{registermainloop}" then
85014          let fnCheckStringFunction = 0
85015       else if Function$ = "{registerexit}" then
85016          let fnCheckStringFunction = 0
85017       else
85018          if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
85019             print "Function ("&function$&") on screen REGISTER is not Supported: The library is out of date or fn not found."
85020          end if
85021       end if
85022    fnend
85023 !
85024 !
89000    def library fnFunctionSwitch(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89010       let fnFunctionSwitch = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89020    fnend
89030    def library fnFunctionSwitch$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89040       let fnFunctionSwitch$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89050    fnend
89060    def library fnFunctionSwitch1(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89070       let fnFunctionSwitch1 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89080    fnend
89090    def library fnFunctionSwitch1$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89100       let fnFunctionSwitch1$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89110    fnend
89120    def library fnFunctionSwitch2(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89130       let fnFunctionSwitch2 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89140    fnend
89150    def library fnFunctionSwitch2$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89160       let fnFunctionSwitch2$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89170    fnend
89180    def library fnFunctionSwitch3(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89190       let fnFunctionSwitch3 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89200    fnend
89210    def library fnFunctionSwitch3$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89220       let fnFunctionSwitch3$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89230    fnend
89240    def library fnFunctionSwitch4(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89250       let fnFunctionSwitch4 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89260    fnend
89270    def library fnFunctionSwitch4$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89280       let fnFunctionSwitch4$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89290    fnend
89300    def library fnFunctionSwitch5(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89310       let fnFunctionSwitch5 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89320    fnend
89330    def library fnFunctionSwitch5$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89340       let fnFunctionSwitch5$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89350    fnend
89360    def library fnFunctionSwitch6(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89370       let fnFunctionSwitch6 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89380    fnend
89390    def library fnFunctionSwitch6$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89400       let fnFunctionSwitch6$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89410    fnend
89420    def library fnFunctionSwitch7(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89430       let fnFunctionSwitch7 = fnFS(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89440    fnend
89450    def library fnFunctionSwitch7$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89460       let fnFunctionSwitch7$ = fnFS$(Function$,mat Subscripts$,mat PassedData$,FieldIndex,FieldText$,ControlIndex,Key$,ExitMode,RepopulateListviews,RedrawListviews,CurrentField,CurrentField$,Prefix$,CurrentKey$,CurrentRec,ParentKey$,DataFile,Window,CurrentRow,LockUser$,Path$,Selecting,mat Disk_F$,mat Disk_F,OnRead,TryToContinue,DisplayOnly,Active,RedrawFrames,RedrawScreens,RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$)
89470    fnend
89480 !
89490  dim DataIsInside
89500 !
89510    def fnFS(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$;___,ReturnValue,ReturnValue$*255,Index)
89520       gosub FunctionSwitch
89530       let fnFS=ReturnValue
89540    fnend
89550    def fnFS$*255(Function$*255,mat Subscripts$,mat PassedData$,&FieldIndex,&FieldText$,&ControlIndex,&Key$,&ExitMode,&RepopulateListviews,&RedrawListviews,&CurrentField,&CurrentField$,&Prefix$,&CurrentKey$,&CurrentRec,&ParentKey$,&DataFile,Window,&CurrentRow,LockUser$,&Path$,&Selecting,mat Disk_F$,mat Disk_F,&OnRead,&TryToContinue,&DisplayOnly,&Active,&RedrawFrames,&RedrawScreens,&RepopulateCombo,mat F$,mat F, mat S$,mat CnvrtIn$,mat FieldsSSubs$,mat FieldsNSubs$,mat FieldName$,mat ControlName$,mat ScreenSubs$,mat Function$,mat SpecWidth,mat Form$,mat ScreenData$,mat ScreenLongData$,mat ScreenData,mat ReturnData$,mat ControlSpec$;___,ReturnValue,ReturnValue$*255,Index)
89560       gosub FunctionSwitch
89570       let fnFS$ = ReturnValue$
89580    fnend
89590 !
89600 !
92000 FunctionSwitch: ! Routine to call custom function
92001 !
92002    if ~DataIsInside then
92003       let fnPopData(2)
92004       if Function$="{{SetData}}" then let DataIsInside=1
92005    end if
92006 !
92007    if ~FileIOLinkageSet then
92008       library "fileio" : fnOpenFile,Fnclosefile,Fngetfilenumber,Fnkey$,FnBuildKey$,Fnreadlayoutarrays,Fndoeslayoutexist,Fnreadallkeys,fnReadRelativeDescription$,fnReadRelUnopenedDescription$,fnReadRelUnopenedNumber,fnUpdateFile,fnLog,fnLogArray,fnSetLogChanges,fnLogChanges,fnErrLog,fnReadLayouts,Fnmakeuniquekey$,FnDisplayLength,FnLength,FnReadDescription$,FnReadUnopenedDescription$,fnReadRecordWhere$,fnUniqueKey,fnReadNumber,fnReadUnopenedNumber,fnReadRelativeNumber,fnNotInFile,fnDataCrawler,fnDataEdit,fnShowData,fnCopyfile
92009       library "fileio" : fnMakeSubProc,fnReadMatchingKeys,fnReadAllNewKeys,fnReadFilterKeys,fnReadEntireLayout,fnReadLayoutHeader,fnReadSubs,fnReadLayoutPath$,fnReadKeyFiles,fnAskCombo$,fnRunProcFile,fnBuildProcFile,fnReadLockedUsers,fnShowMessage,fnExportListviewCSV,fnCsvExport,fnCsvImport
92010       library "screenio" : fnCallScreen$,fnFindSubscript,fnFm$,fnfm,fnDisplayScreen,fnGetUniqueName$,fnIsInputSpec,fnIsOutputSpec,fnDays,fnBR42,fnBR43,fnAnimate,fnPrepareAnimation,fnCloseAnimation,fnFunctionBase,fnListSpec$
92011       let FileIOLinkageSet=1
92012       for Index=1 to udim(mat Subscripts$) : execute (Subscripts$(Index)) : next Index
92013    end if
92014 !
92015    if Function$ = "{additemtosale}" then
92016       let ReturnValue = fnAddItemToSale(FieldText$)
92017    else if Function$ = "{searchinventory}" then
92018       let ReturnValue = fnSearchInventory
92019    else if Function$ = "{paysale}" then
92020       let ReturnValue = fnPaySale
92021    else if Function$ = "{completesale}" then
92022       let ReturnValue = fnCompleteSale
92023    else if Function$ = "{voidsale}" then
92024       let ReturnValue = fnVoidSale
92025    else if Function$ = "{registerenter}" then
92026       let ReturnValue = fnRegisterEnter(mat Form$)
92027    else if Function$ = "{registermainloop}" then
92028       let ReturnValue = fnRegisterMainloop
92029    else if Function$ = "{registerexit}" then
92030       let ReturnValue = fnRegisterExit
92031    else
92032       if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
92033          print "Function ("&function$&") on screen REGISTER is not Supported: The library is out of date or fn not found."
92034       end if
92035    end if
92036 !
92037    if ~DataIsInside or Function$="{{GetData}}" then
92038       let fnPushData(2)
92039       let DataIsInside=0
92040    end if
92041 return
92042 !
99000 OPEN: !   ***** Function  To Call Library Openfile And Proc Subs
99010    def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
99020       dim _FileIOSubs$(1)*800, _loadedsubs$(1)*32
99030       let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
99040       if srch(_loadedsubs$,uprc$(Filename$))<=0 then : mat _loadedsubs$(UDIM(_loadedsubs$)+1) : _loadedsubs$(UDIM(_loadedsubs$))=uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
99050    fnend
99060 !
99980 IGNORE: continue
99990 REPEAT: retry
