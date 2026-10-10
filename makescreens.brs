! makescreens.br - Build and compile the ClockWorks ScreenIO screens  #Autonumber# 100,10
!
! Created 10/09/2026
!
! Writes each screen's records into screenio.dat/screenfld.dat through FileIO, then
! compiles it with fnCompileScreen - no Designer needed. Safe to rerun: each screen's
! old records are deleted and rewritten, so this program is the screens' source.
! Results go to makescreens.log.
!
! Children are built before their parents, because a parent screen draws its child
! screens when it opens.
!
   library "fileio" : fnOpenFile, fnKey$, fnGetFileNumber, fnCloseFile
   library "screenio" : fnCompileScreen
   dim Form$(0)*2000, Screenio$(0)*1023, Screenio(0), Screenfld$(0)*1023, Screenfld(0)
   dim CurrentScreen$*18, Built$(1)*18

   let LogFile=fnGetFileNumber
   open #LogFile: "name=makescreens.log,replace,recl=255",display,output

   let Screenio=Fnopen("screenio",mat Screenio$,mat Screenio,mat Form$)
   let Screenfld=Fnopen("screenfld",mat Screenfld$,mat Screenfld,mat Form$)

   let fnBuildQtyEdit
   let fnBuildSaleLines
   let fnBuildItemSearch
   let fnBuildTender
   let fnBuildBuy
   let fnBuildPurchases
   let fnBuildRegister

   let fnCloseFile(Screenio,"screenio")
   let fnCloseFile(Screenfld,"screenfld")

   for Index=1 to udim(mat Built$)
      if fnCompileScreen(Built$(Index),1) then
         print #LogFile: Built$(Index)&": written and compiled"
      else
         print #LogFile: Built$(Index)&": NOT FOUND by fnCompileScreen"
      end if
   next Index
   close #LogFile:
   stop

! ----- QTYEDIT: change the quantity on one sales line (Change Qty on SALELINES) ------
def fnBuildQtyEdit
   let fnStartScreen("QTYEDIT","sales",8,62,"FFFFFF","3C2614",1,"Change Quantity","Edits the quantity of one sales line. Opened by SALELINES' Change Qty button with the line's key.","","","","{writesaleqty}")
   !         Type       Name                 Field          Text                   Row Col Wid Spec Hgt Function
   let fnCtl("caption", "Caption_ITEMID",    "",            "Item:",                2,  3, 10,  5,  1, "","","R")
   let fnCtl("C",       "Field_ITEMID",      "ITEMID",      "Caption_ITEMID",       2, 14, 10,  8,  1, "","","","",1)
   let fnCtl("C",       "Field_DESCRIPTION", "DESCRIPTION", "Caption_ITEMID",       3, 14, 46, 60,  1, "","","","",1)
   let fnCtl("caption", "Caption_QTY",       "",            "Quantity:",            5,  3, 10,  9,  1, "","","R")
   let fnCtl("C",       "Field_QTY",         "QTY",         "Caption_QTY",          5, 14, 10,  6,  1, "{validatesaleqty}","","R","PIC(ZZ#.##)")
   let fnCtl("button",  "SaveButton",        "",            "Save",                 7, 36, 10,  4,  1, "let ExitMode=SaveAndQuit")
   let fnCtl("button",  "CancelButton",      "",            "Cancel",               7, 49, 10,  6,  1, "let ExitMode=QuitOnly")
fnend

! ----- SALELINES: the current sale's lines, embedded in REGISTER --------------------
def fnBuildSaleLines
   let fnStartScreen("SALELINES","sales",10,90,"FFFFFF","50331A",0,"","Lines of the sale in progress. Embedded in REGISTER, which passes its invoice number as ParentKey$.")
   !         Type        Name                Field          Text              Row Col Wid Spec Hgt Function
   let fnCtl("LISTVIEW", "",                 "",            "",                1,  1, 90,  1,  9, "{salelinesfilter}","LV1")
   let fnCtl("LISTCHLD", "Field_ITEMID",     "ITEMID",      "Item",            1,  0,  8,  8,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_DESCRIPTION","DESCRIPTION", "Description",     1,  0, 40, 60,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_QTY",        "QTY",         "Qty",             1,  0,  6,  6,  1, "","LV1","R","PIC(ZZ#.##)")
   let fnCtl("LISTCHLD", "Field_UNITPRICE",  "UNITPRICE",   "Price",           1,  0, 10, 14,  1, "","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("LISTCHLD", "Field_DISCOUNT",   "DISCOUNT",    "Disc",            1,  0,  8, 14,  1, "","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("LISTCHLD", "Field_EXTENDED",   "EXTENDED",    "Amount",          1,  0, 10, 14,  1, "","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("LISTCHLD", "Field_TAXABLE",    "TAXABLE",     "Tx",              1,  0,  3,  1,  1, "","LV1","C")
   let fnCtl("button",   "ChangeQtyButton",  "",            "Change Qty",     10,  2, 14, 10,  1, "[QTYEDIT]Key$=CurrentKey$")
   let fnCtl("button",   "RemoveLineButton", "",            "Remove Line",    10, 18, 14, 11,  1, "{removesaleline}")
fnend

! ----- ITEMSEARCH: pick an item from inventory (opened by REGISTER's Search) ---------
def fnBuildItemSearch
   let fnStartScreen("ITEMSEARCH","inventory",22,92,"FFFFFF","50331A",1,"Find an Item","Inventory picker for REGISTER's Search button. Returns the selected item number.")
   !         Type        Name                Field          Text              Row Col Wid Spec Hgt Function
   let fnCtl("P",        "SearchPic_1",      "",            "",                2,  3,  2,  0,  1, "","","","",0,"images\search.png")
   let fnCtl("FILTER",   "",                 "",            "SearchPic_1",     2,  6, 50, 60,  1, "","LV1")
   let fnCtl("LISTVIEW", "",                 "",            "",                4,  2, 88,  1, 16, "{itemsearchfilter}","LV1")
   let fnCtl("LISTCHLD", "Field_ITEMID",     "ITEMID",      "Item",            1,  0,  8,  8,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_DESCRIPTION","DESCRIPTION", "Description",     1,  0, 32, 60,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_CATEGORY",   "CATEGORY",    "Category",        1,  0, 12, 12,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_MAKER",      "MAKER",       "Maker",           1,  0, 14, 30,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_PRICE",      "PRICE",       "Price",           1,  0, 10, 14,  1, "","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("LISTCHLD", "Field_QTYONHAND",  "QTYONHAND",   "On Hand",         1,  0,  7,  5,  1, "","LV1","R","N 5")
   let fnCtl("button",   "SelectButton",     "",            "Select",         21, 76, 12,  6,  1, "let ExitMode=SelectAndQuit")
fnend

! ----- TENDER: take payments for the sale in progress (opened by REGISTER's Pay) ----
def fnBuildTender
   let fnStartScreen("TENDER","payment",19,70,"FFFFFF","50331A",1,"Take Payment","Takes payments for the sale in progress. REGISTER passes the invoice number as ParentKey$ and the sale total in PassedData$(1).","{tenderenter}","{tenderexit}","{tendermainloop}")
   !         Type        Name                Field          Text                 Row Col Wid Spec Hgt Function
   let fnCtl("caption",  "Caption_Total",    "",            "Total:",              2,  2, 15,  6,  1, "","","R")
   let fnCtl("C",        "TenderTotal",      "",            "Caption_Total",       2, 18, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)
   let fnCtl("caption",  "Caption_Paid",     "",            "Paid so far:",        3,  2, 15, 12,  1, "","","R")
   let fnCtl("C",        "TenderPaid",       "",            "Caption_Paid",        3, 18, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)
   let fnCtl("caption",  "Caption_Balance",  "",            "Balance Due:",        4,  2, 15, 12,  1, "","","R")
   let fnCtl("C",        "TenderBalance",    "",            "Caption_Balance",     4, 18, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)

   let fnCtl("caption",  "Caption_Amount",   "",            "Amount:",             6,  2, 15,  7,  1, "","","R")
   let fnCtl("C",        "PayAmount",        "",            "Caption_Amount",      6, 18, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("caption",  "Caption_Reference","",            "Check # / Auth:",     7,  2, 15, 15,  1, "","","R")
   let fnCtl("C",        "PayReference",     "",            "Caption_Reference",   7, 18, 30, 30,  1, "")
   let fnCtl("button",   "CashButton",       "",            "Cash",                9,  3, 10,  4,  1, "{paycash}")
   let fnCtl("button",   "CheckButton",      "",            "Check",               9, 15, 10,  5,  1, "{paycheck}")
   let fnCtl("button",   "CardButton",       "",            "Card",                9, 27, 10,  4,  1, "{paycard}")

   let fnCtl("LISTVIEW", "",                 "",            "",                   11,  3, 64,  1,  7, "{tenderfilter}","LV1")
   let fnCtl("LISTCHLD", "Field_METHOD",     "METHOD",      "Method",              1,  0,  8,  6,  1, "","LV1")
   let fnCtl("LISTCHLD", "Field_AMOUNT",     "AMOUNT",      "Amount",              1,  0, 14, 14,  1, "","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("LISTCHLD", "Field_REFERENCE",  "REFERENCE",   "Check # / Auth",      1,  0, 30, 30,  1, "","LV1")
   let fnCtl("button",   "RemovePayButton",  "",            "Remove Payment",     19,  3, 18, 14,  1, "{removepayment}")
   let fnCtl("button",   "DoneButton",       "",            "Done",               19, 56, 12,  4,  1, "let ExitMode=QuitOnly")
fnend

! ----- BUY: one new purchase (opened by PURCHASES' New Purchase button) ---------------
def fnBuildBuy
   let fnStartScreen("BUY","purchase",23,90,"FFFFFF","50331A",1,"New Purchase","Records one purchase: a new item for inventory, or a restock of an item we have. Opened by PURCHASES.","{buyenter}","{buyexit}","","{writepurchase}","{buyinit}")
   let fnCtl("caption","Caption_SOURCE","","Bought From:",2,2,16,12,1,"","","R")
   let fnCtl("C","Field_SOURCE","SOURCE","Caption_SOURCE",2,19,40,40,1,"")
   let fnCtl("caption","Caption_SOURCEINFO","","Seller Contact:",3,2,16,15,1,"","","R")
   let fnCtl("C","Field_SOURCEINFO","SOURCEINFO","Caption_SOURCEINFO",3,19,40,60,1,"")
   let fnCtl("caption","Caption_PURCHDATE","","Date:",4,2,16,5,1,"","","R")
   let fnCtl("C","Field_PURCHDATE","PURCHDATE","Caption_PURCHDATE",4,19,12,10,1,"","","","DATE(mm/dd/ccyy)")

   let fnCtl("caption","Caption_BuyItemId","","Restock Item #:",6,2,16,15,1,"","","R")
   let fnCtl("C","BuyItemId","","Caption_BuyItemId",6,19,10,8,1,"{validatebuyitem}","","U")
   let fnCtl("P","BuySearchIcon","","",6,30,2,0,1,"{buysearch}","","","",0,"images\search.png")
   let fnCtl("C","BuyItemDesc","","Caption_BuyItemId",6,34,54,80,1,"","","","",1)
   let fnCtl("caption","Caption_NewItem","","- or a new item -",7,19,30,17,1,"")

   let fnCtl("caption","Caption_NewType","","Type (C/P):",8,2,16,11,1,"","","R")
   let fnCtl("C","NewType","","Caption_NewType",8,19,3,1,1,"","","U")
   let fnCtl("caption","Caption_NewDesc","","Description:",9,2,16,12,1,"","","R")
   let fnCtl("C","NewDesc","","Caption_NewDesc",9,19,50,60,1,"")
   let fnCtl("caption","Caption_NewCategory","","Category:",10,2,16,9,1,"","","R")
   let fnCtl("C","NewCategory","","Caption_NewCategory",10,19,14,12,1,"")
   let fnCtl("caption","Caption_NewMaker","","Maker:",10,36,8,6,1,"","","R")
   let fnCtl("C","NewMaker","","Caption_NewMaker",10,45,30,30,1,"")
   let fnCtl("caption","Caption_NewOrigin","","Origin:",11,2,16,7,1,"","","R")
   let fnCtl("C","NewOrigin","","Caption_NewOrigin",11,19,14,20,1,"")
   let fnCtl("caption","Caption_NewEra","","Era:",11,36,8,4,1,"","","R")
   let fnCtl("C","NewEra","","Caption_NewEra",11,45,12,12,1,"")
   let fnCtl("caption","Caption_NewCondition","","Condition:",12,2,16,10,1,"","","R")
   let fnCtl("C","NewCondition","","Caption_NewCondition",12,19,12,10,1,"")
   let fnCtl("caption","Caption_NewSerial","","Serial #:",12,36,8,9,1,"","","R")
   let fnCtl("C","NewSerial","","Caption_NewSerial",12,45,20,20,1,"")
   let fnCtl("caption","Caption_NewLocation","","Location:",13,2,16,9,1,"","","R")
   let fnCtl("C","NewLocation","","Caption_NewLocation",13,19,20,20,1,"")
   let fnCtl("caption","Caption_NewUpc","","UPC:",13,40,5,4,1,"","","R")
   let fnCtl("C","NewUpc","","Caption_NewUpc",13,46,16,14,1,"")
   let fnCtl("caption","Caption_NewPrice","","Retail Price:",14,2,16,13,1,"","","R")
   let fnCtl("C","NewPrice","","Caption_NewPrice",14,19,14,14,1,"","","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("caption","Caption_NewTaxable","","Taxable (Y/N):",14,36,15,14,1,"","","R")
   let fnCtl("C","NewTaxable","","Caption_NewTaxable",14,52,3,1,1,"","","U")

   let fnCtl("caption","Caption_QTY","","Quantity:",16,2,16,9,1,"","","R")
   let fnCtl("C","Field_QTY","QTY","Caption_QTY",16,19,6,4,1,"","","R")
   let fnCtl("caption","Caption_UNITCOST","","Unit Cost:",17,2,16,10,1,"","","R")
   let fnCtl("C","Field_UNITCOST","UNITCOST","Caption_UNITCOST",17,19,14,14,1,"","","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("caption","Caption_NOTES","","Notes:",18,2,16,6,1,"","","R")
   let fnCtl("C","Field_NOTES","NOTES","Caption_NOTES",18,19,68,255,1,"")

   let fnCtl("button","SaveButton","","Save",21,60,12,4,1,"{savepurchase}")
   let fnCtl("button","CancelButton","","Cancel",21,75,12,6,1,"let ExitMode=QuitOnly")
fnend

! ----- PURCHASES: the Purchases tab - every purchase, newest first --------------------
def fnBuildPurchases
   let fnStartScreen("PURCHASES","purchase",24,96,"FFFFFF","6B4423",1,"ClockWorks Purchases","The Purchases tab: every purchase, newest first, and New Purchase. Opened by start.brs as a tab.")
   let fnCtl("caption","Title","","Clocks and parts we've bought",2,3,40,29,1,"")
   let fnCtl("button","NewPurchaseButton","","New Purchase...",2,76,18,15,1,"[BUY]")
   let fnCtl("P","SearchPic_1","","",4,3,2,0,1,"","","","",0,"images\search.png")
   let fnCtl("FILTER","","","SearchPic_1",4,6,50,60,1,"","LV1")
   ! A negative LISTVIEW spec width sorts by that column descending: -2 is Purchase #, newest first.
   let fnCtl("LISTVIEW","","","",6,3,90,-2,17,"{purchasesfilter}","LV1")
   let fnCtl("LISTCHLD","Field_PURCHDATE","PURCHDATE","Date",1,0,10,10,1,"","LV1","","DATE(mm/dd/ccyy)")
   let fnCtl("LISTCHLD","Field_PURCHASEID","PURCHASEID","Purchase #",1,0,9,8,1,"","LV1")
   let fnCtl("LISTCHLD","Field_ITEMID","ITEMID","Item",1,0,8,8,1,"","LV1")
   let fnCtl("LISTCHLD","ItemDesc","","Description",1,0,22,60,1,"","LV1")
   let fnCtl("LISTCHLD","Field_SOURCE","SOURCE","Bought From",1,0,14,40,1,"","LV1")
   let fnCtl("LISTCHLD","Field_QTY","QTY","Qty",1,0,5,5,1,"","LV1","R","N 5")
   let fnCtl("LISTCHLD","Field_UNITCOST","UNITCOST","Unit Cost",1,0,10,14,1,"","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
   let fnCtl("LISTCHLD","Field_TOTALCOST","TOTALCOST","Total",1,0,10,14,1,"","LV1","R","PIC(ZZZ,ZZZ,ZZ#.##)")
fnend

! ----- REGISTER: the cash register (main screen) ------------------------------------
def fnBuildRegister
   let fnStartScreen("REGISTER","invoice",24,96,"FFFFFF","6B4423",1,"ClockWorks Register","The ClockWorks cash register. Opened by start.brs, one sale per call.","{registerenter}","{registerexit}","{registermainloop}")
   !         Type       Name                 Field        Text                               Row Col Wid Spec Hgt Function
   let fnCtl("caption", "Title",             "",          "ClockWorks Antique Clocks & Repair", 2,  3, 45, 34,  1, "")
   let fnCtl("caption", "Caption_INVOICENO", "",          "Invoice:",                         2, 66,  9,  8,  1, "","","R")
   let fnCtl("C",       "Field_INVOICENO",   "INVOICENO", "Caption_INVOICENO",                2, 76, 10,  8,  1, "","","","",1)

   let fnCtl("caption", "Caption_ItemEntry", "",          "Item # / UPC:",                    4,  3, 14, 13,  1, "","","R")
   let fnCtl("C",       "ItemEntry",         "",          "Caption_ItemEntry",                4, 18, 16, 14,  1, "{additemtosale}")
   let fnCtl("P",       "SearchIcon",        "",          "",                                 4, 35,  2,  0,  1, "{searchinventory}","","","",0,"images\search.png")
   let fnCtl("caption", "Caption_CUSTNAME",  "",          "Customer:",                        4, 52, 10,  9,  1, "","","R")
   let fnCtl("C",       "Field_CUSTNAME",    "CUSTNAME",  "Caption_CUSTNAME",                 4, 63, 30, 40,  1, "")
   let fnCtl("caption", "Caption_CUSTPHONE", "",          "Phone:",                           5, 52, 10,  6,  1, "","","R")
   let fnCtl("C",       "Field_CUSTPHONE",   "CUSTPHONE", "Caption_CUSTPHONE",                5, 63, 16, 20,  1, "")

   let fnCtl("screen",  "SaleLines",         "SALELINES", "",                                 7,  3, 90,  0, 10, "ParentKey$=f$(iv_invoiceno)","Screen1")

   let fnCtl("caption", "Caption_SUBTOTAL",  "",          "Subtotal:",                       18, 60, 14,  9,  1, "","","R")
   let fnCtl("C",       "Field_SUBTOTAL",    "SUBTOTAL",  "Caption_SUBTOTAL",                18, 75, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)
   let fnCtl("caption", "Caption_TAXAMT",    "",          "Sales Tax:",                      19, 60, 14, 10,  1, "","","R")
   let fnCtl("C",       "Field_TAXAMT",      "TAXAMT",    "Caption_TAXAMT",                  19, 75, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)
   let fnCtl("caption", "Caption_TOTAL",     "",          "TOTAL:",                          20, 60, 14,  6,  1, "","","R")
   let fnCtl("C",       "Field_TOTAL",       "TOTAL",     "Caption_TOTAL",                   20, 75, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)
   let fnCtl("caption", "Caption_AMTPAID",   "",          "Paid so far:",                    21, 60, 14, 12,  1, "","","R")
   let fnCtl("C",       "Field_AMTPAID",     "AMTPAID",   "Caption_AMTPAID",                 21, 75, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)
   let fnCtl("caption", "Caption_BalanceDue","",          "Balance Due:",                    22, 60, 14, 12,  1, "","","R")
   let fnCtl("C",       "BalanceDue",        "",          "Caption_BalanceDue",              22, 75, 14, 14,  1, "","","R","PIC(ZZZ,ZZZ,ZZ#.##)",1)

   let fnCtl("button",  "PayButton",         "",          "Pay...",                          24,  3, 10,  6,  1, "{paysale}")
   let fnCtl("button",  "CompleteButton",    "",          "Complete Sale",                   24, 15, 16, 13,  1, "{completesale}")
   let fnCtl("button",  "VoidButton",        "",          "Void Sale",                       24, 33, 12,  9,  1, "{voidsale}")
   let fnCtl("button",  "DayReportButton",   "",          "Day Report",                      24, 66, 14, 10,  1, "{dayreport}")
fnend

! Deletes any existing records for this screen, then writes its header record, with
! its Enter, Exit, Main Loop, Write and Initialize event functions if it has any.
def fnStartScreen(Code$*18,Layout$*18,Rows,Cols,Fg$,Bg$,Border,WindCap$*80,Notes$*255;EnterFn$*255,ExitFn$*255,LoopFn$*255,WriteFn$*255,InitFn$*255)
   let CurrentScreen$=Code$
   let CaptionCount=TextboxCount=ButtonCount=ScreenCount=0
   let fnRemoveScreen(Code$)
   mat Screenio$=("") : mat Screenio=(0)
   let Screenio$(SI_SCREENCODE)=Code$
   let Screenio$(SI_FILELAY)=Layout$
   let Screenio$(SI_FGCOLOR)=rpad$(Fg$,6)
   let Screenio$(SI_BGCOLOR)=rpad$(Bg$,6)
   let Screenio$(SI_WINDCAP)=WindCap$
   let Screenio$(SI_NOTES)=Notes$
   let Screenio$(SI_ENTERFN)=EnterFn$
   let Screenio$(SI_EXITFN)=ExitFn$
   let Screenio$(SI_LOOPFN)=LoopFn$
   let Screenio$(SI_WRITEFN)=WriteFn$
   let Screenio$(SI_INITFN)=InitFn$
   let Screenio$(SI_CREATEUSER)=Screenio$(SI_MODIFYUSER)="Claude"
   let Screenio(SI_VSIZE)=Rows
   let Screenio(SI_HSIZE)=Cols
   let Screenio(SI_BORDER)=Border
   let Screenio(SI_CREATEDATE)=Screenio(SI_MODIFYDATE)=days(date$)
   write #Screenio, using form$(Screenio): mat Screenio$, mat Screenio
   if Built$(udim(mat Built$))<>"" then mat Built$(udim(mat Built$)+1)
   let Built$(udim(mat Built$))=Code$
fnend

! Removes a screen's header and all its control records, if they exist.
def fnRemoveScreen(Code$*18)
   read #Screenio, using form$(Screenio), key=fnKey$(Screenio,Code$): mat Screenio$, mat Screenio nokey NoHeader
   delete #Screenio:
   NoHeader: !
   restore #Screenfld, key=fnKey$(Screenfld,Code$): nokey ControlsDone
   do
      read #Screenfld, using form$(Screenfld): mat Screenfld$, mat Screenfld eof ControlsDone
      if trim$(Screenfld$(SF_SCREENCODE))<>trim$(Code$) then goto ControlsDone
      delete #Screenfld:
   loop
   ControlsDone: !
fnend

! Writes one control record for the screen being built. Text boxes, buttons, filter
! boxes and listviews get the "W" system colors (black on white). Captions, pictures,
! listview columns and child screens are left blank, so captions inherit the
! screen's own FGCOLOR (white).
def fnCtl(Type$,Name$*50,Field$*50,Text$*255,Row,Col,Width,Spec,Height,Function$*255;Parent$*20,Justify$,CnvrtIn$*255,Protected,Picture$*255)
   mat Screenfld$=("") : mat Screenfld=(0)
   if Parent$="" then
      #Select# Type$ #Case# "caption"
         let CaptionCount+=1
         let Parent$="Caption"&str$(CaptionCount)
      #Case# "C"
         let TextboxCount+=1
         let Parent$="Textbox"&str$(TextboxCount)
      #Case# "button"
         let ButtonCount+=1
         let Parent$="Button"&str$(ButtonCount)
      #Case# "screen"
         let ScreenCount+=1
         let Parent$="Screen"&str$(ScreenCount)
      #End Select#
   end if
   let Screenfld$(SF_SCREENCODE)=CurrentScreen$
   let Screenfld$(SF_CONTROLNAME)=Name$
   let Screenfld$(SF_FIELDNAME)=Field$
   let Screenfld$(SF_DESCRIPTION)=Text$
   let Screenfld$(SF_FIELDTYPE)=Type$
   let Screenfld$(SF_FUNCTION)=Function$
   let Screenfld$(SF_PARENT)=Parent$
   let Screenfld$(SF_JUSTIFY)=Justify$
   let Screenfld$(SF_CNVRTIN)=CnvrtIn$
   let Screenfld$(SF_PICTURE)=Picture$
   if Type$="C" or Type$="button" or Type$="LISTVIEW" or Type$="FILTER" then
      let Screenfld$(SF_FGCOLOR)=Screenfld$(SF_BGCOLOR)="W     "
   else
      let Screenfld$(SF_FGCOLOR)=Screenfld$(SF_BGCOLOR)="      "
   end if
   let Screenfld(SF_VPOSITION)=Row
   let Screenfld(SF_HPOSITION)=Col
   let Screenfld(SF_WIDTH)=Width
   let Screenfld(SF_SPECWIDTH)=Spec
   let Screenfld(SF_HEIGHT)=Height
   let Screenfld(SF_PROTECTED)=Protected
   write #Screenfld, using form$(Screenfld): mat Screenfld$, mat Screenfld
fnend

OPEN: ! ***** Function To Call Library Openfile And Proc Subs  #Autonumber# 99000,10
   def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
      dim _FileIOSubs$(1)*800, _Loadedsubs$(1)*80
      let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
      if Srch(_Loadedsubs$,Uprc$(Filename$))<=0 then : mat _Loadedsubs$(Udim(_Loadedsubs$)+1) : let _Loadedsubs$(Udim(_Loadedsubs$))=Uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
   fnend
