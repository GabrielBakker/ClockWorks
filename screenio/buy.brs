00010 ! screenio\buy.br
00020 ! ScreenIO Generated Helper Library for BUY screen
00030 ! Copyright 2008 by Sage AX
00040 !
00050 ! Compiled On: 10/10/2026
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
01000 Main: ! If you run me as a program, I run the buy screen
01010    library "screenio" : fnfm$
01020    let Ret$=fnfm$("buy","",0,0,"",0,0,0,0,mat PassedData$)
01030    if len(trim$(Ret$)) then
01040       print Ret$
01050    end if
01060    if fkey=93 then execute "system"
01070    stop
01080 !
05000 CustomFunctions: ! Lines 5000 - 70000 are Custom Functions
05001 ! ============================================================
05002 ! Imported From "function\validatenotblank.brs"
05003 ! function\validatenotblank.brs
05004 ! Created on 10/10/2026
05005 !
05006 ! fnValidateNotBlank - Validate event for any field that must be filled in. Returns 0
05007 !   for a blank entry, so ScreenIO puts the previous value back.
05008 !
05009 def fnValidateNotBlank(&FieldText$)
05010    if trim$(FieldText$)="" then
05011       let Msgbox("This field can't be left blank.","Required","OK","EXCL")
05012    else
05013       let fnValidateNotBlank=1
05014    end if
05015 fnend
05016 !
05017 ! Imported From "function\validatebuyitem.brs"
05018 ! function\validatebuyitem.brs
05019 ! Created on 10/10/2026
05020 !
05021 ! fnValidateBuyItem - Validate event for BUY's "Restock item #" box. Blank means a
05022 !   new item. Otherwise the item must exist and be a clock or a part (services
05023 !   can't be purchased); its description and stock show beside the box. Returns 0
05024 !   to make ScreenIO put back what was there before.
05025 !
05026 ! #Include {buyenter}
05027 !
05028 def fnValidateBuyItem(&FieldText$)
05029    let FieldText$=uprc$(trim$(FieldText$))
05030    let S$(SIO_BUYITEMDESC)=""
05031    if FieldText$="" then
05032       let fnValidateBuyItem=1
05033       goto ValidateBuyItemDone
05034    end if
05035    if len(FieldText$)>8 then goto ValidateBuyItemNotFound
05036    read #ByInvFile, using form$(ByInvFile), key=fnKey$(ByInvFile,FieldText$): mat ByInv$, mat ByInv nokey ValidateBuyItemNotFound
05037    if ByInv$(IN_ITEMTYPE)="S" then
05038       let Msgbox(trim$(ByInv$(IN_DESCRIPTION))&" is a service. Only clocks and parts can be purchased.","Can't Purchase a Service","OK","EXCL")
05039    else
05040       let S$(SIO_BUYITEMDESC)=trim$(ByInv$(IN_DESCRIPTION))&"  (on hand: "&str$(ByInv(IN_QTYONHAND))&")"
05041       let fnValidateBuyItem=1
05042    end if
05043    goto ValidateBuyItemDone
05044    ValidateBuyItemNotFound: !
05045    let Msgbox("There's no item "&FieldText$&" in the inventory. Leave the box blank to buy a new item, or use the magnifier to pick one.","Item Not Found","OK","EXCL")
05046    ValidateBuyItemDone: !
05047 fnend
05048 !
05049 ! Imported From "function\buysearch.brs"
05050 ! function\buysearch.brs
05051 ! Created on 10/10/2026
05052 !
05053 ! fnBuySearch - Click event for BUY's magnifier. Shows ITEMSEARCH in restock mode
05054 !   (ParentKey$ "RESTOCK": every active clock and part, even those out of stock) and
05055 !   passes the chosen item through the box's own Validate function.
05056 !
05057 ! #Include {validatebuyitem}
05058 !
05059 def fnBuySearch(;___,ItemId$*255)
05060    let ItemId$=fnfm$("ITEMSEARCH","",0,0,"RESTOCK")
05061    if len(trim$(ItemId$)) then
05062       if fnValidateBuyItem(ItemId$) then let S$(SIO_BUYITEMID)=ItemId$
05063    end if
05064 fnend
05065 !
05066 ! Imported From "function\validatebuytype.brs"
05067 ! function\validatebuytype.brs
05068 ! Created on 10/10/2026
05069 !
05070 ! fnValidateBuyType - Validate event for the New Purchase screen's Type field. Only
05071 !   C (clock) or P (part) can be bought; services can't. Returns 0 for anything else,
05072 !   so ScreenIO puts the previous value back. The field has the AEX attribute, so
05073 !   this runs as soon as the cursor leaves it.
05074 !
05075 def fnValidateBuyType(&FieldText$)
05076    let FieldText$=uprc$(trim$(FieldText$))
05077    if len(FieldText$)=1 and pos("CP",FieldText$) then
05078       let fnValidateBuyType=1
05079    else
05080       let Msgbox("Type must be C (clock) or P (part). Services can't be purchased.","Type","OK","EXCL")
05081    end if
05082 fnend
05083 !
05084 ! Imported From "function\validatenotnegative.brs"
05085 ! function\validatenotnegative.brs
05086 ! Created on 10/10/2026
05087 !
05088 ! fnValidateNotNegative - Validate event for an amount (a price or cost): it must be
05089 !   a number, zero or more. The text may carry the field's PIC formatting, such as
05090 !   1,234.50, so commas are ignored. Returns 0 otherwise, so ScreenIO puts the
05091 !   previous value back.
05092 !
05093 def fnValidateNotNegative(&FieldText$;___,Amount)
05094    let Amount=val(srep$(FieldText$,",","")) conv NotNegativeBad
05095    if Amount<0 then goto NotNegativeBad
05096    let fnValidateNotNegative=1
05097    goto NotNegativeDone
05098    NotNegativeBad: !
05099    let Msgbox("Please enter an amount of zero or more, for example 125.50.","Amount","OK","EXCL")
05100    NotNegativeDone: !
05101 fnend
05102 !
05103 ! Imported From "function\validatequantity.brs"
05104 ! function\validatequantity.brs
05105 ! Created on 10/10/2026
05106 !
05107 ! fnValidateQuantity - Validate event for a quantity bought: a whole number, more
05108 !   than zero. Returns 0 otherwise, so ScreenIO puts the previous value back.
05109 !
05110 def fnValidateQuantity(&FieldText$;___,Number)
05111    let Number=val(srep$(FieldText$,",","")) conv QuantityBad
05112    if Number<=0 or int(Number)<>Number then goto QuantityBad
05113    let fnValidateQuantity=1
05114    goto QuantityDone
05115    QuantityBad: !
05116    let Msgbox("Please enter a whole number, more than zero.","Quantity","OK","EXCL")
05117    QuantityDone: !
05118 fnend
05119 !
05120 ! Imported From "function\savepurchase.brs"
05121 ! function\savepurchase.brs
05122 ! Created on 10/10/2026
05123 !
05124 ! fnSavePurchase - BUY's Save button. Every field checks its own value as it's typed
05125 !   (its Validate function). What's left is what a single field can't check: a
05126 !   Validate only runs when the field changes, so a required field never touched is
05127 !   still blank; and a new item needs a description and a retail price while a
05128 !   restock doesn't. When it's complete, ExitMode=SaveAndQuit runs the Write event
05129 !   (fnWritePurchase) and saves.
05130 !
05131 def fnSavePurchase
05132    if trim$(F$(PU_SOURCE))="" then
05133       let Msgbox("Who did we buy it from? Please fill in Bought From.","Bought From","OK","EXCL")
05134    else if trim$(S$(SIO_BUYITEMID))<>"" then
05135       let ExitMode=SaveAndQuit
05136    else if trim$(S$(SIO_NEWDESC))="" then
05137       let Msgbox("Please give the new item a description, or fill in Restock Item # to add to an item we already have.","New Item","OK","EXCL")
05138    else if val(S$(SIO_NEWPRICE))<=0 then
05139       let Msgbox("Please give the new item a retail price.","New Item","OK","EXCL")
05140    else
05141       let ExitMode=SaveAndQuit
05142    end if
05143 fnend
05144 !
05145 ! Imported From "function\buyenter.brs"
05146 ! function\buyenter.brs
05147 ! Created on 10/10/2026
05148 !
05149 ! fnBuyEnter - Enter event for BUY (New Purchase). Opens inventory and the store
05150 !   settings; fnBuyExit closes them. Inventory is opened OutIn, like every other open
05151 !   of it in this session (BR error 0608 otherwise).
05152 !
05153 dim ByInv$(1)*1024, ByInv(1), ByInvFile
05154 dim ByCfg$(1)*1024, ByCfg(1), ByCfgFile
05155 !
05156 def fnBuyEnter(mat Form$)
05157    let ByInvFile=fnOpen("inventory",mat ByInv$,mat ByInv,mat Form$)
05158    let ByCfgFile=fnOpen("storecfg",mat ByCfg$,mat ByCfg,mat Form$)
05159 fnend
05160 !
05161 ! Imported From "function\buyinit.brs"
05162 ! function\buyinit.brs
05163 ! Created on 10/10/2026
05164 !
05165 ! fnBuyInit - Initialize event for BUY (New Purchase): the starting values for a new
05166 !   purchase. It's dated today, for one item; a new item is a clock (what the store
05167 !   buys most) and taxable (its check box starts checked) unless the clerk says
05168 !   otherwise.
05169 !
05170 def fnBuyInit
05171    let F(PU_PURCHDATE)=days(date$("ccyymmdd"),"ccyymmdd")
05172    let F(PU_QTY)=1
05173    let S$(SIO_NEWTYPE)="C"
05174    let S$(SIO_NEWTAXABLE)="Y"
05175 fnend
05176 !
05177 ! Imported From "function\writepurchase.brs"
05178 ! function\writepurchase.brs
05179 ! Created on 10/10/2026
05180 !
05181 ! fnWritePurchase - Write event for BUY. Runs just before ScreenIO saves the
05182 !   purchase (fnSavePurchase has already checked it). Gives the purchase the next
05183 !   purchase number from the store settings and works out its total, then updates
05184 !   inventory: a restock adds the quantity and takes the latest unit cost; a new
05185 !   item gets the next item number for its type (CLKnnnn or PRTnnnn) and is added.
05186 !
05187 ! #Include {buyenter}
05188 ! #Include {nextinvid}
05189 !
05190 def fnWritePurchase(;___,ItemId$*8,Prefix$*3)
05191    read #ByCfgFile, using form$(ByCfgFile), rec=1, reserve: mat ByCfg$, mat ByCfg norec WritePurchaseNoConfig
05192    let F$(PU_PURCHASEID)="P"&lpad$(str$(ByCfg(CF_NEXTPURCHASE)),7,"0")
05193    let ByCfg(CF_NEXTPURCHASE)+=1
05194    rewrite #ByCfgFile, using form$(ByCfgFile): mat ByCfg$, mat ByCfg
05195    release #ByCfgFile:
05196    WritePurchaseNoConfig: !
05197    let F(PU_TOTALCOST)=round(F(PU_UNITCOST)*F(PU_QTY),2)
05198 !
05199    if trim$(S$(SIO_BUYITEMID))<>"" then
05200       let ItemId$=uprc$(trim$(S$(SIO_BUYITEMID)))
05201       read #ByInvFile, using form$(ByInvFile), key=fnKey$(ByInvFile,ItemId$), reserve: mat ByInv$, mat ByInv nokey WritePurchaseDone
05202       let ByInv(IN_QTYONHAND)+=F(PU_QTY)
05203       let ByInv(IN_COST)=F(PU_UNITCOST)
05204       rewrite #ByInvFile, using form$(ByInvFile): mat ByInv$, mat ByInv
05205       release #ByInvFile:
05206    else
05207       if uprc$(trim$(S$(SIO_NEWTYPE)))="C" then
05208          let Prefix$="CLK"
05209       else
05210          let Prefix$="PRT"
05211       end if
05212       let ItemId$=fnNextInvId$(ByInvFile,Prefix$)
05213       mat ByInv$=("") : mat ByInv=(0)
05214       let ByInv$(IN_ITEMID)=ItemId$
05215       let ByInv$(IN_UPC)=S$(SIO_NEWUPC)
05216       let ByInv$(IN_ITEMTYPE)=uprc$(trim$(S$(SIO_NEWTYPE)))
05217       let ByInv$(IN_DESCRIPTION)=S$(SIO_NEWDESC)
05218       let ByInv$(IN_CATEGORY)=S$(SIO_NEWCATEGORY)
05219       let ByInv$(IN_MAKER)=S$(SIO_NEWMAKER)
05220       let ByInv$(IN_ORIGIN)=S$(SIO_NEWORIGIN)
05221       let ByInv$(IN_ERA)=S$(SIO_NEWERA)
05222       let ByInv$(IN_CONDITION)=S$(SIO_NEWCONDITION)
05223       let ByInv$(IN_SERIALNO)=S$(SIO_NEWSERIAL)
05224       let ByInv$(IN_LOCATION)=S$(SIO_NEWLOCATION)
05225       let ByInv(IN_COST)=F(PU_UNITCOST)
05226       let ByInv(IN_PRICE)=val(S$(SIO_NEWPRICE))
05227       let ByInv(IN_QTYONHAND)=F(PU_QTY)
05228       let ByInv$(IN_TAXABLE)=uprc$(trim$(S$(SIO_NEWTAXABLE)))
05229       if ByInv$(IN_TAXABLE)<>"N" then let ByInv$(IN_TAXABLE)="Y"
05230       let ByInv$(IN_STATUS)="A"
05231       let ByInv(IN_DATEADDED)=F(PU_PURCHDATE)
05232       let ByInv$(IN_NOTES)=F$(PU_NOTES)
05233       write #ByInvFile, using form$(ByInvFile): mat ByInv$, mat ByInv
05234    end if
05235    let F$(PU_ITEMID)=ItemId$
05236    WritePurchaseDone: !
05237 fnend
05238 !
05239 !
05240 ! Imported From "function\buyexit.brs"
05241 ! function\buyexit.brs
05242 ! Created on 10/10/2026
05243 !
05244 ! fnBuyExit - Exit event for BUY. Closes the files fnBuyEnter opened.
05245 !
05246 def fnBuyExit
05247    if ByInvFile then
05248       let fnCloseFile(ByInvFile,"inventory")
05249       let ByInvFile=0
05250    end if
05251    if ByCfgFile then
05252       let fnCloseFile(ByCfgFile,"storecfg")
05253       let ByCfgFile=0
05254    end if
05255 fnend
05256 !
05257 ! Imported From "function\nextinvid.brs"
05258 ! function\nextinvid.brs
05259 ! Created on 10/10/2026
05260 !
05261 ! fnNextInvId$ - The next free item number with a given prefix (CLK, PRT or SVC),
05262 !   read from the inventory file open on InvFile: the highest number in use plus one,
05263 !   as in CLK0013. Shared by BUY (new items bought) and INVEDIT (items added there).
05264 !
05265 dim NxInv$(1)*1024, NxInv(1)
05266 !
05267 def fnNextInvId$*8(InvFile,Prefix$*3;___,Highest)
05268    restore #InvFile, key>=fnKey$(InvFile,Prefix$): nokey NextInvIdDone
05269    do
05270       read #InvFile, using form$(InvFile): mat NxInv$, mat NxInv eof NextInvIdDone
05271       if NxInv$(IN_ITEMID)(1:3)<>Prefix$ then exit do
05272       let Highest=max(Highest,val(trim$(NxInv$(IN_ITEMID)(4:8)))) conv NextInvIdSkip
05273       NextInvIdSkip: !
05274    loop
05275    NextInvIdDone: !
05276    let fnNextInvId$=Prefix$&lpad$(str$(Highest+1),4,"0")
05277 fnend
05278 !
05279 !
05280 !
85000    def library fnCheckStringFunction(Function$*255)
85001    if Function$ = "{validatenotblank}" then
85002       let fnCheckStringFunction = 0
85003    else if Function$ = "{validatebuyitem}" then
85004       let fnCheckStringFunction = 0
85005    else if Function$ = "{buysearch}" then
85006       let fnCheckStringFunction = 0
85007    else if Function$ = "{validatebuytype}" then
85008       let fnCheckStringFunction = 0
85009    else if Function$ = "{validatenotnegative}" then
85010       let fnCheckStringFunction = 0
85011    else if Function$ = "{validatequantity}" then
85012       let fnCheckStringFunction = 0
85013    else if Function$ = "{validatenotnegative}" then
85014       let fnCheckStringFunction = 0
85015    else if Function$ = "{savepurchase}" then
85016       let fnCheckStringFunction = 0
85017       else if Function$ = "{buyenter}" then
85018          let fnCheckStringFunction = 0
85019       else if Function$ = "{buyinit}" then
85020          let fnCheckStringFunction = 0
85021       else if Function$ = "{writepurchase}" then
85022          let fnCheckStringFunction = 0
85023       else if Function$ = "{buyexit}" then
85024          let fnCheckStringFunction = 0
85025       else
85026          if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
85027             print "Function ("&function$&") on screen BUY is not Supported: The library is out of date or fn not found."
85028          end if
85029       end if
85030    fnend
85031 !
85032 !
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
92015    if Function$ = "{validatenotblank}" then
92016       let ReturnValue = fnValidateNotBlank(FieldText$)
92017    else if Function$ = "{validatebuyitem}" then
92018       let ReturnValue = fnValidateBuyItem(FieldText$)
92019    else if Function$ = "{buysearch}" then
92020       let ReturnValue = fnBuySearch
92021    else if Function$ = "{validatebuytype}" then
92022       let ReturnValue = fnValidateBuyType(FieldText$)
92023    else if Function$ = "{validatenotnegative}" then
92024       let ReturnValue = fnValidateNotNegative(FieldText$)
92025    else if Function$ = "{validatequantity}" then
92026       let ReturnValue = fnValidateQuantity(FieldText$)
92027    else if Function$ = "{validatenotnegative}" then
92028       let ReturnValue = fnValidateNotNegative(FieldText$)
92029    else if Function$ = "{savepurchase}" then
92030       let ReturnValue = fnSavePurchase
92031    else if Function$ = "{buyenter}" then
92032       let ReturnValue = fnBuyEnter(mat Form$)
92033    else if Function$ = "{buyinit}" then
92034       let ReturnValue = fnBuyInit
92035    else if Function$ = "{writepurchase}" then
92036       let ReturnValue = fnWritePurchase
92037    else if Function$ = "{buyexit}" then
92038       let ReturnValue = fnBuyExit
92039    else
92040       if Function$<>"{{GetData}}" and Function$<>"{{SetData}}" then
92041          print "Function ("&function$&") on screen BUY is not Supported: The library is out of date or fn not found."
92042       end if
92043    end if
92044 !
92045    if ~DataIsInside or Function$="{{GetData}}" then
92046       let fnPushData(2)
92047       let DataIsInside=0
92048    end if
92049 return
92050 !
99000 OPEN: !   ***** Function  To Call Library Openfile And Proc Subs
99010    def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
99020       dim _FileIOSubs$(1)*800, _loadedsubs$(1)*32
99030       let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
99040       if srch(_loadedsubs$,uprc$(Filename$))<=0 then : mat _loadedsubs$(UDIM(_loadedsubs$)+1) : _loadedsubs$(UDIM(_loadedsubs$))=uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
99050    fnend
99060 !
99980 IGNORE: continue
99990 REPEAT: retry
