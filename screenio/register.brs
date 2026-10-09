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
05016 ! fnTotalSale - Reads the current sale's lines: totals them into the invoice and
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
05108 def fnTotalSale(ItemId$*8,&ItemQty,&LastLine;___,Subtotal,Taxable)
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
05121    let F(IV_SUBTOTAL)=Subtotal
05122    let F(IV_TAXAMT)=round(Taxable*F(IV_TAXRATE),2)
05123    let F(IV_TOTAL)=Subtotal-F(IV_DISCOUNT)+F(IV_TAXAMT)
05124    let S$(SIO_BALANCEDUE)=str$(F(IV_TOTAL)-F(IV_AMTPAID))
05125 fnend
05126 !
05127 ! Imported From "function\searchinventory.brs"
05128 ! function\searchinventory.brs
05129 ! Created on 10/09/2026
05130 !
05131 ! fnSearchInventory - Click event for REGISTER's magnifier picture (its search
05132 !   button). Shows the ITEMSEARCH list of items (Enter selects one) and passes the
05133 !   chosen item number through the item box's own Validate function, exactly as if
05134 !   it had been typed, so it is rung up the same way and the box is left blank.
05135 !
05136 ! #Include {additemtosale}
05137 !
05138 def fnSearchInventory(;___,ItemId$*255)
05139    let ItemId$=fnfm$("ITEMSEARCH")
05140    if len(trim$(ItemId$)) then let fnAddItemToSale(ItemId$)
05141 fnend
05142 !
05143 ! Imported From "function\registerenter.brs"
05144 ! function\registerenter.brs
05145 ! Created on 10/09/2026
05146 !
05147 ! fnRegisterEnter - Enter event for REGISTER. Opens the files the register's
05148 !   functions use while a sale is rung up. fnRegisterExit closes them again.
05149 !
05150 !   Inventory is opened OutIn, not input-only, even for lookups: ITEMSEARCH (opened
05151 !   from the Search button) binds to inventory, and a ScreenIO screen opens its file
05152 !   OutIn. BR refuses an OutIn open of a file this session already has open for
05153 !   input (error 0608), so the OutIn open must come first.
05154 !
05155 dim Inv$(1)*1024, Inv(1), InvFile, InvUpcFile
05156 dim Sales$(1)*1024, Sales(1), SalesFile
05157 dim Cfg$(1)*1024, Cfg(1), CfgFile
05158 !
05159 def fnRegisterEnter(mat Form$)
05160    let InvFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$)
05161    let InvUpcFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$,0,4)
05162    let SalesFile=fnOpen("sales",mat Sales$,mat Sales,mat Form$)
05163    let CfgFile=fnOpen("storecfg",mat Cfg$,mat Cfg,mat Form$)
05164 fnend
05165 !
05166 ! Imported From "function\registermainloop.brs"
05167 ! function\registermainloop.brs
05168 ! Created on 10/09/2026
05169 !
05170 ! fnRegisterMainloop - Main Loop event for REGISTER. When the clerk tries to leave
05171 !   (Exit button, or the window's close X) while a sale has items on it, asks whether
05172 !   to abandon the sale. Yes removes its lines from the sales file and quits; No keeps
05173 !   the register open.
05174 !
05175 !   ScreenIO's own AskSaveAndQuit can't do this: it doesn't know the sale's lines are
05176 !   already in the sales file. And it has to be Main Loop: Main Loop runs after a
05177 !   button has set ExitMode, so it can still cancel the exit, while the screen's Exit
05178 !   event runs only once leaving is final. A cancelled key is reset the house way:
05179 !   fkey(-1) unless the window was closed (93), Function=-1 and ExitMode=0.
05180 !
05181 ! fnAbandonSale - Deletes the current invoice's lines, and hands its invoice number
05182 !   back if no later sale has taken a number since.
05183 !
05184 !   While a sale is open it also re-totals the sale on every pass, so the totals
05185 !   follow any line changed or removed inside SALELINES (Change Qty, Remove Line).
05186 !
05187 ! #Include {registerenter}
05188 ! #Include {additemtosale}
05189 !
05190 def fnRegisterMainloop(;___,ItemQty,LastLine)
05191    if F$(IV_STATUS)="O" then let fnTotalSale("",ItemQty,LastLine)
05192    if ExitMode and F$(IV_STATUS)="O" then
05193       if 2==Msgbox("This sale has items on it. Are you sure you want to quit? They will be removed from the sale.","Quit This Sale?","yN","QST") then
05194          let fnAbandonSale
05195          let ExitMode=QuitOnly
05196       else
05197          if fkey<>93 then let fkey(-1)
05198          let Function=-1
05199          let ExitMode=0
05200       end if
05201    end if
05202 fnend
05203 !
05204 def fnAbandonSale(;___,InvoiceNo$*8)
05205    let InvoiceNo$=F$(IV_INVOICENO)
05206    restore #SalesFile, key>=rpad$(InvoiceNo$,8)&chr$(0)&chr$(0): nokey AbandonLinesDone
05207    do
05208       read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof AbandonLinesDone
05209       if Sales$(SL_INVOICENO)<>InvoiceNo$ then exit do
05210       delete #SalesFile:
05211    loop
05212    AbandonLinesDone: !
05213 !
05214    read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec AbandonNumberDone
05215    if Cfg(CF_NEXTINVOICE)=val(InvoiceNo$)+1 then
05216       let Cfg(CF_NEXTINVOICE)-=1
05217       rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
05218    end if
05219    release #CfgFile:
05220    AbandonNumberDone: !
05221 fnend
05222 !
05223 ! Imported From "function\registerexit.brs"
05224 ! function\registerexit.brs
05225 ! Created on 10/09/2026
05226 !
05227 ! fnRegisterExit - Exit event for REGISTER. Closes the files fnRegisterEnter opened.
05228 !
05229 def fnRegisterExit
05230    if InvFile then
05231       let fnCloseFile(InvFile,"inventory")
05232       let InvFile=0
05233    end if
05234    if InvUpcFile then
05235       let fnCloseFile(InvUpcFile,"inventory")
05236       let InvUpcFile=0
05237    end if
05238    if SalesFile then
05239       let fnCloseFile(SalesFile,"sales")
05240       let SalesFile=0
05241    end if
05242    if CfgFile then
05243       let fnCloseFile(CfgFile,"storecfg")
05244       let CfgFile=0
05245    end if
05246 fnend
05247 !
05248 ! Imported From "function\saleqtyrules.brs"
05249 ! function\saleqtyrules.brs
05250 ! Created on 10/09/2026
05251 !
05252 ! fnSaleQtyOk - The rules for a quantity on a sales line, shared by the item box
05253 !   (REGISTER) and Change Qty (QTYEDIT). Returns 1 if Qty is allowed; otherwise
05254 !   explains why in a Msgbox and returns 0.
05255 !
05256 !   ItemType$     C=Clock, P=Part, S=Service (from the inventory record)
05257 !   Qty           the quantity wanted on this line
05258 !   OnHand        inventory quantity on hand (ignored for services, never stocked)
05259 !   MaxPerSale    the most of this item one sale may have (0 means no limit), e.g. 1
05260 !                 for a service charged per job
05261 !   OtherQty      how many of this item are already on the sale on other lines
05262 !   Description$  the item's description, for the messages
05263 !
05264 def fnSaleQtyOk(ItemType$,Qty,OnHand,MaxPerSale,OtherQty,Description$*60)
05265    if Qty<=0 then
05266       let Msgbox("The quantity has to be more than zero.","Quantity","OK","EXCL")
05267    else if Qty>999.99 then
05268       let Msgbox("The largest quantity a line can hold is 999.99.","Quantity","OK","EXCL")
05269    else if round(Qty,2)<>Qty then
05270       let Msgbox("Quantities can have at most two decimal places, for example 1.25 hours.","Quantity","OK","EXCL")
05271    else if ItemType$<>"S" and int(Qty)<>Qty then
05272       let Msgbox(trim$(Description$)&" is sold in whole numbers. Only labor and other services can have a fraction.","Quantity","OK","EXCL")
05273    else if MaxPerSale and OtherQty+Qty>MaxPerSale then
05274       if MaxPerSale=1 then
05275          let Msgbox(trim$(Description$)&" is charged once per sale, and it's already on this sale.","Once per Sale","OK","EXCL")
05276       else
05277          let Msgbox("A sale can have at most "&str$(MaxPerSale)&" of "&trim$(Description$)&", and "&str$(OtherQty)&" are already on it.","Limit per Sale","OK","EXCL")
05278       end if
05279    else if ItemType$<>"S" and OtherQty+Qty>OnHand then
05280       if OnHand=1 then
05281          let Msgbox(trim$(Description$)&" is one of a kind, and it's already on this sale.","Already on the Sale","OK","EXCL")
05282       else
05283          let Msgbox("We only have "&str$(OnHand)&" of "&trim$(Description$)&" in stock, and "&str$(OtherQty)&" of them are already on this sale.","Not Enough Stock","OK","EXCL")
05284       end if
05285    else
05286       let fnSaleQtyOk=1
05287    end if
05288 fnend
05289 !
05290 !
05291 !
85000    def library fnCheckStringFunction(Function$*255)
85001    if Function$ = "{additemtosale}" then
85002       let fnCheckStringFunction = 0
85003    else if Function$ = "{searchinventory}" then
85004       let fnCheckStringFunction = 0
85005       else if Function$ = "{registerenter}" then
85006          let fnCheckStringFunction = 0
85007       else if Function$ = "{registermainloop}" then
85008          let fnCheckStringFunction = 0
85009       else if Function$ = "{registerexit}" then
85010          let fnCheckStringFunction = 0
85011       else
85012          if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
85013             print "Function ("&function$&") on screen REGISTER is not Supported: The library is out of date or fn not found."
85014          end if
85015       end if
85016    fnend
85017 !
85018 !
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
92019    else if Function$ = "{registerenter}" then
92020       let ReturnValue = fnRegisterEnter(mat Form$)
92021    else if Function$ = "{registermainloop}" then
92022       let ReturnValue = fnRegisterMainloop
92023    else if Function$ = "{registerexit}" then
92024       let ReturnValue = fnRegisterExit
92025    else
92026       if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
92027          print "Function ("&function$&") on screen REGISTER is not Supported: The library is out of date or fn not found."
92028       end if
92029    end if
92030 !
92031    if ~DataIsInside or Function$="{{GetData}}" then
92032       let fnPushData(2)
92033       let DataIsInside=0
92034    end if
92035 return
92036 !
99000 OPEN: !   ***** Function  To Call Library Openfile And Proc Subs
99010    def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
99020       dim _FileIOSubs$(1)*800, _loadedsubs$(1)*32
99030       let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
99040       if srch(_loadedsubs$,uprc$(Filename$))<=0 then : mat _loadedsubs$(UDIM(_loadedsubs$)+1) : _loadedsubs$(UDIM(_loadedsubs$))=uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
99050    fnend
99060 !
99980 IGNORE: continue
99990 REPEAT: retry
