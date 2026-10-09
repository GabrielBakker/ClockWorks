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
05007 !   whatever was typed or scanned, then clears the box for the next item.
05008 !
05009 ! fnRingUpItem - Looks an item up by item number, then by UPC, and checks it can be
05010 !   sold. On the first item of a sale it starts the invoice. Then it writes the sales
05011 !   line, updates the totals, and asks ScreenIO to redraw SALELINES. Nothing is
05012 !   redrawn when the item can't be added. Also used by the Search button.
05013 !
05014 ! fnTotalSale - Reads the current sale's lines: totals them into the invoice and
05015 !   Balance Due, and reports how many of one item are on the sale and the last line
05016 !   number used.
05017 !
05018 ! Files are opened by fnRegisterEnter (function\registerenter.brs).
05019 !
05020 ! #Include {registerenter}
05021 !
05022 def fnAddItemToSale(&FieldText$)
05023    if len(trim$(FieldText$)) then
05024       let fnRingUpItem(FieldText$)
05025       let FieldText$=""
05026    end if
05027    let fnAddItemToSale=1
05028 fnend
05029 !
05030 def fnRingUpItem(Entry$*255;___,ItemQty,LastLine)
05031    let Entry$=uprc$(trim$(Entry$))
05032    mat Inv$=("") : mat Inv=(0)
05033 !
05034    if len(Entry$)>8 then goto RingUpTryUpc
05035    read #InvFile, using form$(InvFile), key=fnKey$(InvFile,Entry$): mat Inv$, mat Inv nokey RingUpTryUpc
05036    goto RingUpFound
05037    RingUpTryUpc: !
05038    if len(Entry$)>14 then goto RingUpNotFound
05039    read #InvUpcFile, using form$(InvUpcFile), key=fnKey$(InvUpcFile,Entry$): mat Inv$, mat Inv nokey RingUpNotFound
05040    goto RingUpFound
05041    RingUpNotFound: !
05042    let Msgbox("I couldn't find """&Entry$&""" in the inventory, either as an item number or as a UPC. Please check it and try again, or use Search.","Item Not Found","OK","EXCL")
05043    goto RingUpDone
05044 !
05045    RingUpFound: !
05046    if Inv$(IN_STATUS)<>"A" then
05047       let Msgbox(trim$(Inv$(IN_DESCRIPTION))&" ("&trim$(Inv$(IN_ITEMID))&") isn't available for sale right now.","Not Available","OK","EXCL")
05048       goto RingUpDone
05049    end if
05050 !
05051    let fnTotalSale(Inv$(IN_ITEMID),ItemQty,LastLine)
05052    if Inv$(IN_ITEMTYPE)<>"S" and ItemQty>=Inv(IN_QTYONHAND) then
05053       if Inv(IN_QTYONHAND)=1 then
05054          let Msgbox(trim$(Inv$(IN_DESCRIPTION))&" is one of a kind, and it's already on this sale.","Already on the Sale","OK","EXCL")
05055       else
05056          let Msgbox("We only have "&str$(Inv(IN_QTYONHAND))&" of "&trim$(Inv$(IN_DESCRIPTION))&" in stock, and all of them are already on this sale.","Not Enough Stock","OK","EXCL")
05057       end if
05058       goto RingUpDone
05059    end if
05060 !
05061    if trim$(F$(IV_INVOICENO))="" then
05062       if ~fnStartInvoice then goto RingUpDone
05063    end if
05064 !
05065    mat Sales$=("") : mat Sales=(0)
05066    let Sales$(SL_INVOICENO)=F$(IV_INVOICENO)
05067    let Sales(SL_LINENO)=LastLine+1
05068    let Sales$(SL_ITEMID)=Inv$(IN_ITEMID)
05069    let Sales$(SL_DESCRIPTION)=Inv$(IN_DESCRIPTION)
05070    let Sales(SL_QTY)=1
05071    let Sales(SL_UNITPRICE)=Inv(IN_PRICE)
05072    let Sales(SL_EXTENDED)=Inv(IN_PRICE)
05073    let Sales$(SL_TAXABLE)=Inv$(IN_TAXABLE)
05074    let Sales(SL_SALEDATE)=F(IV_INVDATE)
05075    write #SalesFile, using form$(SalesFile): mat Sales$, mat Sales
05076 !
05077    let fnTotalSale(Inv$(IN_ITEMID),ItemQty,LastLine)
05078    let RedrawScreens=1
05079    let fnRingUpItem=1
05080    RingUpDone: !
05081 fnend
05082 !
05083 ! Takes the next invoice number from the store settings and fills in the new
05084 ! invoice's header fields. Returns 0 if the store settings record is missing.
05085 def fnStartInvoice
05086    read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec StartInvoiceNoConfig
05087    let F$(IV_INVOICENO)=lpad$(str$(Cfg(CF_NEXTINVOICE)),8,"0")
05088    let Cfg(CF_NEXTINVOICE)+=1
05089    rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
05090    release #CfgFile:
05091    let F(IV_INVDATE)=days(date$("ccyymmdd"),"ccyymmdd")
05092    let F$(IV_INVTIME)=time$
05093    let F$(IV_CLERK)=login_name$
05094    let F$(IV_STATUS)="O"
05095    let F(IV_TAXRATE)=Cfg(CF_TAXRATE)
05096    let fnStartInvoice=1
05097    goto StartInvoiceDone
05098    StartInvoiceNoConfig: !
05099    let Msgbox("The store settings record is missing, so I can't number the invoice. Run seeddata to create it.","Store Settings Missing","OK","ERR")
05100    StartInvoiceDone: !
05101 fnend
05102 !
05103 def fnTotalSale(ItemId$*8,&ItemQty,&LastLine;___,Subtotal,Taxable)
05104    let ItemQty=LastLine=0
05105    if trim$(F$(IV_INVOICENO))="" then goto TotalSaleDone
05106    restore #SalesFile, key>=rpad$(F$(IV_INVOICENO),8)&chr$(0)&chr$(0): nokey TotalSaleDone
05107    do
05108       read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof TotalSaleDone
05109       if Sales$(SL_INVOICENO)<>F$(IV_INVOICENO) then exit do
05110       let Subtotal+=Sales(SL_EXTENDED)
05111       if Sales$(SL_TAXABLE)="Y" then let Taxable+=Sales(SL_EXTENDED)
05112       if Sales$(SL_ITEMID)=ItemId$ then let ItemQty+=Sales(SL_QTY)
05113       let LastLine=max(LastLine,Sales(SL_LINENO))
05114    loop
05115    TotalSaleDone: !
05116    let F(IV_SUBTOTAL)=Subtotal
05117    let F(IV_TAXAMT)=round(Taxable*F(IV_TAXRATE),2)
05118    let F(IV_TOTAL)=Subtotal-F(IV_DISCOUNT)+F(IV_TAXAMT)
05119    let S$(SIO_BALANCEDUE)=str$(F(IV_TOTAL)-F(IV_AMTPAID))
05120 fnend
05121 !
05122 ! Imported From "function\searchinventory.brs"
05123 ! function\searchinventory.brs
05124 ! Created on 10/09/2026
05125 !
05126 ! fnSearchInventory - Click event for REGISTER's Search button and its magnifier
05127 !   picture. Shows the ITEMSEARCH list of items (Enter selects one) and passes the
05128 !   chosen item number through the item box's own Validate function, exactly as if
05129 !   it had been typed, so it is rung up the same way and the box is left blank.
05130 !
05131 ! #Include {additemtosale}
05132 !
05133 def fnSearchInventory(;___,ItemId$*255)
05134    let ItemId$=fnfm$("ITEMSEARCH")
05135    if len(trim$(ItemId$)) then let fnAddItemToSale(ItemId$)
05136 fnend
05137 !
05138 ! Imported From "function\registerenter.brs"
05139 ! function\registerenter.brs
05140 ! Created on 10/09/2026
05141 !
05142 ! fnRegisterEnter - Enter event for REGISTER. Opens the files the register's
05143 !   functions use while a sale is rung up. fnRegisterExit closes them again.
05144 !
05145 !   Inventory is opened OutIn, not input-only, even for lookups: ITEMSEARCH (opened
05146 !   from the Search button) binds to inventory, and a ScreenIO screen opens its file
05147 !   OutIn. BR refuses an OutIn open of a file this session already has open for
05148 !   input (error 0608), so the OutIn open must come first.
05149 !
05150 dim Inv$(1)*1024, Inv(1), InvFile, InvUpcFile
05151 dim Sales$(1)*1024, Sales(1), SalesFile
05152 dim Cfg$(1)*1024, Cfg(1), CfgFile
05153 !
05154 def fnRegisterEnter(mat Form$)
05155    let InvFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$)
05156    let InvUpcFile=fnOpen("inventory",mat Inv$,mat Inv,mat Form$,0,4)
05157    let SalesFile=fnOpen("sales",mat Sales$,mat Sales,mat Form$)
05158    let CfgFile=fnOpen("storecfg",mat Cfg$,mat Cfg,mat Form$)
05159 fnend
05160 !
05161 ! Imported From "function\registermainloop.brs"
05162 ! function\registermainloop.brs
05163 ! Created on 10/09/2026
05164 !
05165 ! fnRegisterMainloop - Main Loop event for REGISTER. When the clerk tries to leave
05166 !   (Exit button, or the window's close X) while a sale has items on it, asks whether
05167 !   to abandon the sale. Yes removes its lines from the sales file and quits; No keeps
05168 !   the register open.
05169 !
05170 !   ScreenIO's own AskSaveAndQuit can't do this: it doesn't know the sale's lines are
05171 !   already in the sales file. And it has to be Main Loop: Main Loop runs after a
05172 !   button has set ExitMode, so it can still cancel the exit, while the screen's Exit
05173 !   event runs only once leaving is final. A cancelled key is reset the house way:
05174 !   fkey(-1) unless the window was closed (93), Function=-1 and ExitMode=0.
05175 !
05176 ! fnAbandonSale - Deletes the current invoice's lines, and hands its invoice number
05177 !   back if no later sale has taken a number since.
05178 !
05179 ! #Include {registerenter}
05180 !
05181 def fnRegisterMainloop
05182    if ExitMode and F$(IV_STATUS)="O" then
05183       if 2==Msgbox("This sale has items on it. Are you sure you want to quit? They will be removed from the sale.","Quit This Sale?","yN","QST") then
05184          let fnAbandonSale
05185          let ExitMode=QuitOnly
05186       else
05187          if fkey<>93 then let fkey(-1)
05188          let Function=-1
05189          let ExitMode=0
05190       end if
05191    end if
05192 fnend
05193 !
05194 def fnAbandonSale(;___,InvoiceNo$*8)
05195    let InvoiceNo$=F$(IV_INVOICENO)
05196    restore #SalesFile, key>=rpad$(InvoiceNo$,8)&chr$(0)&chr$(0): nokey AbandonLinesDone
05197    do
05198       read #SalesFile, using form$(SalesFile): mat Sales$, mat Sales eof AbandonLinesDone
05199       if Sales$(SL_INVOICENO)<>InvoiceNo$ then exit do
05200       delete #SalesFile:
05201    loop
05202    AbandonLinesDone: !
05203 !
05204    read #CfgFile, using form$(CfgFile), rec=1, reserve: mat Cfg$, mat Cfg norec AbandonNumberDone
05205    if Cfg(CF_NEXTINVOICE)=val(InvoiceNo$)+1 then
05206       let Cfg(CF_NEXTINVOICE)-=1
05207       rewrite #CfgFile, using form$(CfgFile): mat Cfg$, mat Cfg
05208    end if
05209    release #CfgFile:
05210    AbandonNumberDone: !
05211 fnend
05212 !
05213 ! Imported From "function\registerexit.brs"
05214 ! function\registerexit.brs
05215 ! Created on 10/09/2026
05216 !
05217 ! fnRegisterExit - Exit event for REGISTER. Closes the files fnRegisterEnter opened.
05218 !
05219 def fnRegisterExit
05220    if InvFile then
05221       let fnCloseFile(InvFile,"inventory")
05222       let InvFile=0
05223    end if
05224    if InvUpcFile then
05225       let fnCloseFile(InvUpcFile,"inventory")
05226       let InvUpcFile=0
05227    end if
05228    if SalesFile then
05229       let fnCloseFile(SalesFile,"sales")
05230       let SalesFile=0
05231    end if
05232    if CfgFile then
05233       let fnCloseFile(CfgFile,"storecfg")
05234       let CfgFile=0
05235    end if
05236 fnend
05237 !
05238 !
05239 !
85000    def library fnCheckStringFunction(Function$*255)
85001    if Function$ = "{additemtosale}" then
85002       let fnCheckStringFunction = 0
85003    else if Function$ = "{searchinventory}" then
85004       let fnCheckStringFunction = 0
85005    else if Function$ = "{searchinventory}" then
85006       let fnCheckStringFunction = 0
85007       else if Function$ = "{registerenter}" then
85008          let fnCheckStringFunction = 0
85009       else if Function$ = "{registermainloop}" then
85010          let fnCheckStringFunction = 0
85011       else if Function$ = "{registerexit}" then
85012          let fnCheckStringFunction = 0
85013       else
85014          if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
85015             print "Function ("&function$&") on screen REGISTER is not Supported: The library is out of date or fn not found."
85016          end if
85017       end if
85018    fnend
85019 !
85020 !
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
92019    else if Function$ = "{searchinventory}" then
92020       let ReturnValue = fnSearchInventory
92021    else if Function$ = "{registerenter}" then
92022       let ReturnValue = fnRegisterEnter(mat Form$)
92023    else if Function$ = "{registermainloop}" then
92024       let ReturnValue = fnRegisterMainloop
92025    else if Function$ = "{registerexit}" then
92026       let ReturnValue = fnRegisterExit
92027    else
92028       if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
92029          print "Function ("&function$&") on screen REGISTER is not Supported: The library is out of date or fn not found."
92030       end if
92031    end if
92032 !
92033    if ~DataIsInside or Function$="{{GetData}}" then
92034       let fnPushData(2)
92035       let DataIsInside=0
92036    end if
92037 return
92038 !
99000 OPEN: !   ***** Function  To Call Library Openfile And Proc Subs
99010    def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
99020       dim _FileIOSubs$(1)*800, _loadedsubs$(1)*32
99030       let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
99040       if srch(_loadedsubs$,uprc$(Filename$))<=0 then : mat _loadedsubs$(UDIM(_loadedsubs$)+1) : _loadedsubs$(UDIM(_loadedsubs$))=uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
99050    fnend
99060 !
99980 IGNORE: continue
99990 REPEAT: retry
