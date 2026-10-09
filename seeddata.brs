! seeddata.br - Load the ClockWorks training sample data  #Autonumber# 100,10
!
! Created 10/09/2026
!
! Fills an empty ClockWorks system with made-up training data: the store settings
! record, antique clocks, parts and repair services in inventory, and one purchase
! record for every clock and part, showing where the store bought it.
!
! Only runs against an empty inventory file, so it can't double-load. Run initfiles
! first if the data files don't exist yet. Results go to seeddata.log.
!
   library "fileio" : fnOpenFile, fnCloseFile, fnGetFileNumber
   dim Form$(0)*2000
   dim Inventory$(0)*1024, Inventory(0), Purchase$(0)*1024, Purchase(0)
   dim Storecfg$(0)*1024, Storecfg(0)

   let LogFile=fnGetFileNumber
   open #LogFile: "name=seeddata.log,replace,recl=255",display,output

   let Inventory=Fnopen("inventory",mat Inventory$,mat Inventory,mat Form$)
   let Purchase=Fnopen("purchase",mat Purchase$,mat Purchase,mat Form$)
   let Storecfg=Fnopen("storecfg",mat Storecfg$,mat Storecfg,mat Form$)

   if lrec(Inventory)>0 or lrec(Storecfg)>0 then
      print #LogFile: "Sample data already loaded - nothing done."
      goto Finished
   end if

   let Today=days(date$("ccyymmdd"),"ccyymmdd")
   let NextPurchase=501

   ! ----- Antique clocks:  Id, Type, Description, Category, Maker, Origin, Era, Condition, Serial, Location, Cost, Price, Qty, Taxable, Days ago bought, Bought from, Notes
   let fnAddItem("CLK0001","C","Seth Thomas Adamantine Mantel Clock","Mantel","Seth Thomas","USA","c. 1905","Restored","2214","Front Window",285,595,1,"Y",120,"Estate of Margaret Holloway","Faux-marble celluloid case, lion-head side mounts. Movement cleaned and bushed.")
   let fnAddItem("CLK0002","C","Howard Miller Tall Case Clock, Burl Walnut","Tall Case","Howard Miller","USA","1978","Excellent","610-220","Showroom A",1450,3200,1,"Y",95,"Riverside Antique Auction","Westminster, Whittington and St. Michael chimes. Moon-phase dial.")
   let fnAddItem("CLK0003","C","Black Forest Cuckoo Clock, 8-Day, Hunter Motif","Cuckoo","Hubert Herr","Germany","c. 1955","Good","","Wall 2",240,525,2,"Y",60,"Brass & Oak Dealers Co.","Hand-carved stag, rifle and game birds. Dancers and music box work.")
   let fnAddItem("CLK0004","C","Vienna Regulator Wall Clock, Single Weight","Wall","Gustav Becker","Austria","c. 1890","Restored","1287530","Wall 1",900,1950,1,"Y",200,"Estate of Margaret Holloway","Walnut case with beveled glass. New suspension spring fitted.")
   let fnAddItem("CLK0005","C","French Brass Carriage Clock with Repeater","Carriage","L'Epee","France","c. 1880","Excellent","3317","Case 1",650,1450,1,"Y",45,"Riverside Antique Auction","Push-button hour repeat, original leather travel case.")

   let fnAddItem("CLK0006","C","Ansonia Crystal Regulator","Mantel","Ansonia","USA","c. 1904","Good","","Case 2",700,1600,1,"Y",150,"Walk-in seller","Four beveled glass panels, visible Brocot escapement.")
   let fnAddItem("CLK0007","C","Waltham Pocket Watch, 17 Jewel, Gold Filled","Pocket Watch","Waltham","USA","1912","Running","18765432","Case 1",180,425,2,"Y",30,"Brass & Oak Dealers Co.","Hunter case, engraved monogram on back.")
   let fnAddItem("CLK0008","C","Sessions Kitchen Shelf Clock, Oak","Kitchen","Sessions","USA","c. 1915","Fair","","Shelf 3",95,225,3,"Y",75,"Walk-in seller","Pressed oak gingerbread case. Strikes hour and half hour.")
   let fnAddItem("CLK0009","C","Junghans Westminster Chime Bracket Clock","Bracket","Junghans","Germany","c. 1925","Good","","Showroom B",380,875,1,"Y",110,"Riverside Antique Auction","Ebonized case with brass handle and feet.")
   let fnAddItem("CLK0010","C","English Fusee Dial Wall Clock, Mahogany","Wall","Unsigned","England","c. 1860","Restored","","Wall 1",1100,2400,1,"Y",180,"Estate of Margaret Holloway","Single-fusee movement, 12-inch painted dial, railway-station style.")

   let fnAddItem("CLK0011","C","Atmos Perpetual Motion Clock","Mantel","Jaeger-LeCoultre","Switzerland","1962","Excellent","140221","Case 2",950,2100,1,"Y",20,"Brass & Oak Dealers Co.","Runs on air temperature changes. Includes original box and papers.")
   let fnAddItem("CLK0012","C","Banjo Wall Clock, Eagle Finial","Wall","E. Howard","USA","c. 1920","Good","","Wall 2",520,1150,1,"Y",90,"Walk-in seller","Reverse-painted tablets show a harbor scene.")

   ! ----- Stock parts
   let fnAddItem("PRT0001","P","Clock Key, Double-End Brass","Parts","","","","New","","Counter",3.50,12,40,"Y",60,"Merritt Clock Supply","Assorted sizes 3 through 12.")
   let fnAddItem("PRT0002","P","Mainspring, Standard American 8-Day","Parts","","","","New","","Back Room",6,24.95,15,"Y",60,"Merritt Clock Supply","")
   let fnAddItem("PRT0003","P","Suspension Spring, Vienna Regulator","Parts","","","","New","","Back Room",4,14.50,10,"Y",60,"Merritt Clock Supply","")
   let fnAddItem("PRT0004","P","Clock Oil, Synthetic, 5 ml","Parts","","","","New","","Counter",6,15.95,25,"Y",60,"Merritt Clock Supply","")

   ! ----- Repair services (billed at the register, never stocked, labor not taxed)
   let fnAddItem("SVC0001","S","Clean & Oil Movement (Mantel or Wall)","Service","","","","","","",0,175,0,"N",0,"","Disassemble, clean, inspect, oil and regulate.")
   let fnAddItem("SVC0002","S","Clean & Oil Movement (Tall Case)","Service","","","","","","",0,295,0,"N",0,"","Includes weights, pendulum and chime rods.")
   let fnAddItem("SVC0003","S","Mainspring Replacement Labor","Service","","","","","","",0,85,0,"N",0,"","Spring sold separately.")
   let fnAddItem("SVC0004","S","Repair Labor, per Hour","Service","","","","","","",0,75,0,"N",0,"","")
   let fnAddItem("SVC0005","S","House Call: Set Up Tall Case Clock","Service","","","","","","",0,125,0,"N",0,"","Delivery, leveling and beat setting within 25 miles.")

   ! ----- Store settings (one record)
   let Storecfg$(CF_STORENAME)="ClockWorks Antique Clocks & Repair"
   let Storecfg$(CF_ADDRESS1)="1887 Pendulum Lane"
   let Storecfg$(CF_ADDRESS2)="Suite 12"
   let Storecfg$(CF_CITYSTZIP)="Harmony Falls, OR 97000"
   let Storecfg$(CF_PHONE)="(555) 014-1887"
   let Storecfg(CF_TAXRATE)=0.0725
   let Storecfg(CF_NEXTINVOICE)=1001
   let Storecfg(CF_NEXTPURCHASE)=NextPurchase
   let Storecfg$(CF_RECEIPTMSG)="Thank you! Every clock we sell is cleaned, oiled and guaranteed for 90 days."
   write #Storecfg, using form$(Storecfg): mat Storecfg$, mat Storecfg

   print #LogFile: "Loaded "&str$(lrec(Inventory))&" inventory items, "&str$(lrec(Purchase))&" purchases, "&str$(lrec(Storecfg))&" store record."

Finished: !
   let fnCloseFile(Inventory,"inventory")
   let fnCloseFile(Purchase,"purchase")
   let fnCloseFile(Storecfg,"storecfg")
   close #LogFile:
   stop

! Writes one inventory item, plus a purchase record for anything the store stocks.
def fnAddItem(Id$,Type$,Desc$*60,Category$,Maker$*30,Origin$*20,Era$*12,Condition$,Serial$*20,Location$*20,Cost,Price,Qty,Taxable$,DaysAgo,Source$*40,Notes$*255)
   mat Inventory$=("") : mat Inventory=(0)
   let Inventory$(IN_ITEMID)=Id$
   let Inventory$(IN_ITEMTYPE)=Type$
   let Inventory$(IN_DESCRIPTION)=Desc$
   let Inventory$(IN_CATEGORY)=Category$
   let Inventory$(IN_MAKER)=Maker$
   let Inventory$(IN_ORIGIN)=Origin$
   let Inventory$(IN_ERA)=Era$
   let Inventory$(IN_CONDITION)=Condition$
   let Inventory$(IN_SERIALNO)=Serial$
   let Inventory$(IN_LOCATION)=Location$
   let Inventory(IN_COST)=Cost
   let Inventory(IN_PRICE)=Price
   let Inventory(IN_QTYONHAND)=Qty
   let Inventory$(IN_TAXABLE)=Taxable$
   let Inventory$(IN_STATUS)="A"
   let Inventory(IN_DATEADDED)=Today-DaysAgo
   let Inventory$(IN_NOTES)=Notes$
   write #Inventory, using form$(Inventory): mat Inventory$, mat Inventory

   if Type$<>"S" then
      mat Purchase$=("") : mat Purchase=(0)
      let Purchase$(PU_PURCHASEID)="P"&lpad$(str$(NextPurchase),7,"0")
      let Purchase$(PU_ITEMID)=Id$
      let Purchase(PU_PURCHDATE)=Today-DaysAgo
      let Purchase$(PU_SOURCE)=Source$
      let Purchase(PU_QTY)=Qty
      let Purchase(PU_UNITCOST)=Cost
      let Purchase(PU_TOTALCOST)=Cost*Qty
      write #Purchase, using form$(Purchase): mat Purchase$, mat Purchase
      let NextPurchase+=1
   end if
fnend

OPEN: ! ***** Function To Call Library Openfile And Proc Subs  #Autonumber# 99000,10
   def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
      dim _FileIOSubs$(1)*800, _Loadedsubs$(1)*80
      let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
      if Srch(_Loadedsubs$,Uprc$(Filename$))<=0 then : mat _Loadedsubs$(Udim(_Loadedsubs$)+1) : let _Loadedsubs$(Udim(_Loadedsubs$))=Uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
   fnend
