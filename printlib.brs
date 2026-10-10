! printlib.br - ClockWorks receipts and reports  #Autonumber# 100,10
!
! Created 10/09/2026
!
! fnAfterSale - Called by start.brs whenever a sale ends. If the sale was completed
!   (not voided), offers to print its receipt.
! fnPrintReceipt - Prints one invoice as a register receipt, 42 columns wide.
! fnPrintDayReport - Prints the end of day report for one day: every invoice, the
!   totals, payments by method with the cash the drawer should hold, and items sold.
!
! Both print to a Windows print preview unless given another printer name (a file
! name works too, which is how they are tested headlessly).
!
   print "This is a library and cannot be run directly." : stop

   dim Iv$(1)*1024, Iv(1), Sl$(1)*1024, Sl(1), Py$(1)*1024, Py(1), Cf$(1)*1024, Cf(1), Form$(1)*2000
   dim IvFile, SlFile, PyFile, CfFile, Prn, LibraryLinkage
   dim Rule$*42, Line$*132
   dim ItemId$(1)*8, ItemDesc$(1)*60, ItemQty(1), ItemAmount(1)

! Printer$ is for automated use and testing: when given, the receipt goes there
! without asking. start.brs leaves it out, so the clerk is asked.
def library fnAfterSale(InvoiceNo$*8;Printer$*255,___,Status$)
   let fnLibraryLinkage
   let IvFile=Fnopen("invoice",mat Iv$,mat Iv,mat Form$,1)
   read #IvFile, using form$(IvFile), key=fnKey$(IvFile,InvoiceNo$): mat Iv$, mat Iv nokey AfterSaleRead
   let Status$=Iv$(IV_STATUS)
   AfterSaleRead: !
   close #IvFile:
   if Status$="P" then
      if trim$(Printer$)<>"" then
         let fnPrintReceipt(InvoiceNo$,Printer$)
      else if 2==Msgbox("Sale "&trim$(InvoiceNo$)&" is complete. Print a receipt?","Receipt","Yn","QST") then
         let fnPrintReceipt(InvoiceNo$)
      end if
   end if
fnend

def library fnPrintReceipt(InvoiceNo$*8;Printer$*255,___,Text$*255,Footer$*255)
   let fnLibraryLinkage
   if trim$(Printer$)="" then let Printer$="PREVIEW:/DEFAULT"
   let fnOpenFiles
   read #IvFile, using form$(IvFile), key=fnKey$(IvFile,InvoiceNo$): mat Iv$, mat Iv nokey ReceiptNotFound
   read #CfFile, using form$(CfFile), rec=1: mat Cf$, mat Cf norec ReceiptNoConfig
   ReceiptNoConfig: !
   let Rule$=rpt$("-",42)

   let Prn=fnGetFileNumber
   open #Prn: fnPrinterSpec$(Printer$),display,output
   print #Prn: fnCenter$(Cf$(CF_STORENAME))
   print #Prn: fnCenter$(Cf$(CF_ADDRESS1))
   if trim$(Cf$(CF_ADDRESS2))<>"" then print #Prn: fnCenter$(Cf$(CF_ADDRESS2))
   print #Prn: fnCenter$(Cf$(CF_CITYSTZIP))
   print #Prn: fnCenter$(Cf$(CF_PHONE))
   print #Prn: ""
   print #Prn: rpad$("Invoice "&trim$(Iv$(IV_INVOICENO)),26)&lpad$(date$(Iv(IV_INVDATE),"mm/dd/ccyy")&" "&Iv$(IV_INVTIME)(1:5),16)
   print #Prn: "Clerk: "&trim$(Iv$(IV_CLERK))
   if trim$(Iv$(IV_CUSTNAME))<>"" then print #Prn: "Customer: "&trim$(Iv$(IV_CUSTNAME))&"  "&trim$(Iv$(IV_CUSTPHONE))
   if Iv$(IV_STATUS)="V" then print #Prn: fnCenter$("*** VOID ***")
   print #Prn: Rule$

   restore #SlFile, key>=rpad$(Iv$(IV_INVOICENO),8)&chr$(0)&chr$(0): nokey ReceiptLinesDone
   do
      read #SlFile, using form$(SlFile): mat Sl$, mat Sl eof ReceiptLinesDone
      if Sl$(SL_INVOICENO)<>Iv$(IV_INVOICENO) then exit do
      print #Prn: trim$(Sl$(SL_DESCRIPTION))(1:42)
      let Text$="  "&fnQty$(Sl(SL_QTY))&" @ "&fnMoney$(Sl(SL_UNITPRICE))
      if Sl$(SL_TAXABLE)<>"Y" then let Text$(inf:0)="  (no tax)"
      print #Prn: fnAmountLine$(Text$,Sl(SL_EXTENDED))
   loop
   ReceiptLinesDone: !

   print #Prn: Rule$
   print #Prn: fnAmountLine$("Subtotal",Iv(IV_SUBTOTAL))
   print #Prn: fnAmountLine$("Sales tax ("&fnRate$(Iv(IV_TAXRATE))&")",Iv(IV_TAXAMT))
   print #Prn: fnAmountLine$("TOTAL",Iv(IV_TOTAL))
   print #Prn: ""

   restore #PyFile, key>=rpad$(Iv$(IV_INVOICENO),8)&chr$(0): nokey ReceiptPaymentsDone
   do
      read #PyFile, using form$(PyFile): mat Py$, mat Py eof ReceiptPaymentsDone
      if Py$(PY_INVOICENO)<>Iv$(IV_INVOICENO) then exit do
      print #Prn: fnAmountLine$(fnMethod$(Py$(PY_METHOD))&"  "&trim$(Py$(PY_REFERENCE)),Py(PY_AMOUNT))
   loop
   ReceiptPaymentsDone: !
   if Iv(IV_CHANGEDUE)>0 then print #Prn: fnAmountLine$("Change",Iv(IV_CHANGEDUE))

   print #Prn: ""
   let Footer$=trim$(Cf$(CF_RECEIPTMSG))
   do while len(Footer$)
      let Text$=fnWrap$(Footer$,42)
      print #Prn: fnCenter$(Text$)
   loop
   close #Prn:
   goto ReceiptClose
   ReceiptNotFound: !
   let Msgbox("I couldn't find invoice "&trim$(InvoiceNo$)&" to print.","Receipt","OK","EXCL")
   ReceiptClose: !
   let fnCloseFiles
fnend

def library fnPrintDayReport(Day;Printer$*255,___,Text$*255,Key$*11,Index,Spot,Count,Subtotal,Tax,Total,VoidCount,VoidTotal,Cash,Check,Card,Change)
   let fnLibraryLinkage
   if trim$(Printer$)="" then let Printer$="PREVIEW:/DEFAULT"
   mat ItemId$(0) : mat ItemDesc$(0) : mat ItemQty(0) : mat ItemAmount(0)
   let fnOpenFiles(2)
   read #CfFile, using form$(CfFile), rec=1: mat Cf$, mat Cf norec ReportNoConfig
   ReportNoConfig: !

   let Prn=fnGetFileNumber
   open #Prn: fnPrinterSpec$(Printer$),display,output
   print #Prn: trim$(Cf$(CF_STORENAME))
   print #Prn: "End of Day Report for "&date$(Day,"mm/dd/ccyy")&"      (printed "&date$(days(date$("ccyymmdd"),"ccyymmdd"),"mm/dd/ccyy")&" "&time$(1:5)&")"
   print #Prn: ""
   print #Prn: "Invoice   Time   Clerk         Customer                 Status          Total"
   print #Prn: rpt$("-",80)

   let Key$=cnvrt$("BH 3",Day)&rpt$(chr$(0),8)
   restore #IvFile, key>=Key$: nokey ReportInvoicesDone
   do
      read #IvFile, using form$(IvFile): mat Iv$, mat Iv eof ReportInvoicesDone
      if Iv(IV_INVDATE)<>Day then exit do
      let Count+=1
      let Line$=rpad$(trim$(Iv$(IV_INVOICENO)),10)&rpad$(Iv$(IV_INVTIME)(1:5),7)&rpad$(trim$(Iv$(IV_CLERK))(1:13),14)&rpad$(trim$(Iv$(IV_CUSTNAME))(1:24),25)
      if Iv$(IV_STATUS)="V" then
         let Line$(inf:0)=rpad$("Void",6)
         let VoidCount+=1
         let VoidTotal+=Iv(IV_TOTAL)
      else
         let Line$(inf:0)=rpad$("Paid",6)
         let Subtotal+=Iv(IV_SUBTOTAL)
         let Tax+=Iv(IV_TAXAMT)
         let Total+=Iv(IV_TOTAL)
         let Change+=Iv(IV_CHANGEDUE)
         let fnAddItemsSold(Iv$(IV_INVOICENO),mat ItemId$,mat ItemDesc$,mat ItemQty,mat ItemAmount)
      end if
      let Line$(inf:0)=lpad$(fnMoney$(Iv(IV_TOTAL)),14)
      print #Prn: Line$

      restore #PyFile, key>=rpad$(Iv$(IV_INVOICENO),8)&chr$(0): nokey ReportPaymentsDone
      do
         read #PyFile, using form$(PyFile): mat Py$, mat Py eof ReportPaymentsDone
         if Py$(PY_INVOICENO)<>Iv$(IV_INVOICENO) then exit do
         if Iv$(IV_STATUS)<>"V" then
            if trim$(Py$(PY_METHOD))="CASH" then let Cash+=Py(PY_AMOUNT)
            if trim$(Py$(PY_METHOD))="CHECK" then let Check+=Py(PY_AMOUNT)
            if trim$(Py$(PY_METHOD))="CARD" then let Card+=Py(PY_AMOUNT)
         end if
      loop
      ReportPaymentsDone: !
   loop
   ReportInvoicesDone: !

   print #Prn: rpt$("-",80)
   if Count=0 then print #Prn: "No sales on this day."
   print #Prn: ""
   print #Prn: "Sales completed:  "&str$(Count-VoidCount)
   print #Prn: "   Subtotal       "&lpad$(fnMoney$(Subtotal),14)
   print #Prn: "   Sales tax      "&lpad$(fnMoney$(Tax),14)
   print #Prn: "   Total          "&lpad$(fnMoney$(Total),14)
   print #Prn: "Sales voided:     "&str$(VoidCount)&"   (worth "&fnMoney$(VoidTotal)&", nothing collected)"
   print #Prn: ""
   print #Prn: "Payments on completed sales"
   print #Prn: "   Cash taken     "&lpad$(fnMoney$(Cash),14)
   print #Prn: "   Change given   "&lpad$(fnMoney$(Change),14)
   print #Prn: "   Net cash       "&lpad$(fnMoney$(Cash-Change),14)&"   <- should be in the drawer"
   print #Prn: "   Checks         "&lpad$(fnMoney$(Check),14)
   print #Prn: "   Cards          "&lpad$(fnMoney$(Card),14)
   print #Prn: "   Total          "&lpad$(fnMoney$(Cash-Change+Check+Card),14)
   print #Prn: ""
   print #Prn: "Items sold"
   print #Prn: "   Item      Description                                  Qty         Amount"
   for Index=1 to udim(mat ItemId$)
      print #Prn: "   "&rpad$(ItemId$(Index),10)&rpad$(trim$(ItemDesc$(Index))(1:42),43)&lpad$(fnQty$(ItemQty(Index)),6)&lpad$(fnMoney$(ItemAmount(Index)),15)
   next Index
   if udim(mat ItemId$)=0 then print #Prn: "   (none)"
   close #Prn:
   let fnCloseFiles
fnend

! Adds one completed invoice's lines to the items-sold totals, one row per item.
def fnAddItemsSold(InvoiceNo$*8,mat ItemId$,mat ItemDesc$,mat ItemQty,mat ItemAmount;___,Spot)
   restore #SlFile, key>=rpad$(InvoiceNo$,8)&chr$(0)&chr$(0): nokey ItemsSoldDone
   do
      read #SlFile, using form$(SlFile): mat Sl$, mat Sl eof ItemsSoldDone
      if Sl$(SL_INVOICENO)<>InvoiceNo$ then exit do
      let Spot=srch(mat ItemId$,Sl$(SL_ITEMID))
      if Spot<=0 then
         let Spot=udim(mat ItemId$)+1
         mat ItemId$(Spot) : mat ItemDesc$(Spot) : mat ItemQty(Spot) : mat ItemAmount(Spot)
         let ItemId$(Spot)=Sl$(SL_ITEMID)
         let ItemDesc$(Spot)=Sl$(SL_DESCRIPTION)
      end if
      let ItemQty(Spot)+=Sl(SL_QTY)
      let ItemAmount(Spot)+=Sl(SL_EXTENDED)
   loop
   ItemsSoldDone: !
fnend

! Opens the files the printouts read, input only. InvoiceKey picks the invoice
! index: 1 (by number, the default) or 2 (by date, for the day report).
def fnOpenFiles(;InvoiceKey)
   if InvoiceKey=0 then let InvoiceKey=1
   let IvFile=Fnopen("invoice",mat Iv$,mat Iv,mat Form$,1,InvoiceKey)
   let SlFile=Fnopen("sales",mat Sl$,mat Sl,mat Form$,1)
   let PyFile=Fnopen("payment",mat Py$,mat Py,mat Form$,1)
   let CfFile=Fnopen("storecfg",mat Cf$,mat Cf,mat Form$,1)
fnend

def fnCloseFiles
   close #IvFile:
   close #SlFile:
   close #PyFile:
   close #CfFile:
fnend

! The OPEN string for a printout: a printer such as PREVIEW:/DEFAULT, or a file name
! (replaced if it exists), which is how the printouts are tested headlessly.
def fnPrinterSpec$*300(Printer$*255)
   if pos(Printer$,":/") then
      let fnPrinterSpec$="name="&Printer$&",recl=200"
   else
      let fnPrinterSpec$="name="&Printer$&",replace,recl=200"
   end if
fnend

! Money as 1,234.56; negative amounts get a leading minus sign (PIC itself can't
! format a negative number: that is BR error 0002).
def fnMoney$*20(Amount)
   if Amount<0 then
      let fnMoney$="-"&trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",-Amount))
   else
      let fnMoney$=trim$(cnvrt$("PIC(ZZZ,ZZZ,ZZ#.##)",Amount))
   end if
fnend

! Whole quantities print without decimals (2); fractions print with two (1.50).
def fnQty$*12(Qty)
   if int(Qty)=Qty then
      let fnQty$=str$(Qty)
   else
      let fnQty$=trim$(cnvrt$("PIC(ZZ#.##)",Qty))
   end if
fnend

def fnRate$*12(Rate)=trim$(cnvrt$("PIC(Z#.##)",Rate*100))&"%"

def fnMethod$*10(Method$)
   if trim$(Method$)="CASH" then let fnMethod$="Cash"
   if trim$(Method$)="CHECK" then let fnMethod$="Check"
   if trim$(Method$)="CARD" then let fnMethod$="Card"
fnend

! A receipt line: text on the left, an amount right-aligned in a 42-column line.
def fnAmountLine$*42(Text$*255,Amount)=rpad$(Text$(1:29),30)&lpad$(fnMoney$(Amount),12)

def fnCenter$*42(Text$*255)
   let Text$=trim$(Text$)(1:42)
   let fnCenter$=rpt$(" ",int((42-len(Text$))/2))&Text$
fnend

! Takes the next line of up to Width characters off the front of Text$, breaking at
! a space where it can, and returns it. Text$ keeps the rest.
def fnWrap$*255(&Text$,Width;___,Cut)
   let Text$=trim$(Text$)
   if len(Text$)<=Width then
      let fnWrap$=Text$
      let Text$=""
   else
      let Cut=pos(Text$(1:Width+1)," ",-1)
      if Cut<=1 then let Cut=Width+1
      let fnWrap$=Text$(1:Cut-1)
      let Text$=Text$(Cut:len(Text$))
   end if
fnend

! A DEF LIBRARY function still has to be linked before code in its own library can
! call it (error 2282 otherwise): fnAfterSale calls fnPrintReceipt. The linkage is
! unnamed on purpose - naming "printlib" here would load a second copy of it.
def fnLibraryLinkage
   if ~LibraryLinkage then
      library : fnPrintReceipt
      library "fileio" : fnOpenFile, fnKey$, fnCloseFile, fnGetFileNumber
      let LibraryLinkage=1
   end if
fnend

OPEN: ! ***** Function To Call Library Openfile And Proc Subs  #Autonumber# 99000,10
   def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
      dim _FileIOSubs$(1)*800, _Loadedsubs$(1)*80
      let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
      if Srch(_Loadedsubs$,Uprc$(Filename$))<=0 then : mat _Loadedsubs$(Udim(_Loadedsubs$)+1) : let _Loadedsubs$(Udim(_Loadedsubs$))=Uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
   fnend
