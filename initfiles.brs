! initfiles.br - Create or verify every ClockWorks data file  #Autonumber# 100,10
!
! Created 10/09/2026
!
! Opens each ClockWorks layout once through FileIO. FileIO creates any data file
! (and its key files) that doesn't exist yet, and upgrades any whose layout version
! has gone up. Safe to run any time: existing data is left alone.
!
! Writes one line per file to initfiles.log, so a headless run can be checked.
!
   library "fileio" : fnOpenFile, fnCloseFile, fnGetFileNumber
   dim Layout$(1)*20, Form$(0)*2000, F$(0)*1024, F(0)

   str2mat("inventory,purchase,invoice,sales,payment,storecfg",mat Layout$,",")

   let LogFile=fnGetFileNumber
   open #LogFile: "name=initfiles.log,replace,recl=255",display,output

   for Index=1 to udim(mat Layout$)
      let FileNumber=Fnopen(Layout$(Index),mat F$,mat F,mat Form$)
      if FileNumber>0 then
         print #LogFile: Layout$(Index)&": ok, "&file$(FileNumber)&", "&str$(lrec(FileNumber))&" records"
         let fnCloseFile(FileNumber,Layout$(Index))
      else
         print #LogFile: Layout$(Index)&": FAILED to open"
      end if
   next Index

   print #LogFile: "initfiles finished"
   close #LogFile:
   stop

OPEN: ! ***** Function To Call Library Openfile And Proc Subs  #Autonumber# 99000,10
   def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
      dim _FileIOSubs$(1)*800, _Loadedsubs$(1)*80
      let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
      if Srch(_Loadedsubs$,Uprc$(Filename$))<=0 then : mat _Loadedsubs$(Udim(_Loadedsubs$)+1) : let _Loadedsubs$(Udim(_Loadedsubs$))=Uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
   fnend
