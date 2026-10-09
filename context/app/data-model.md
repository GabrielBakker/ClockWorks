# BR application data model (file schemas)

Data dictionary for **9** BR data files, parsed from `FileLay`. Dual purpose:
an LLM uses this to know what files/fields exist and how they are keyed when writing BR
code; an LSP uses field names + FORM types to validate/complete `OPEN`/`READ…USING` and
to build correct key expressions.

Per file: the data path, record length, key indexes (with their key-file name and composing fields — the
order you concatenate values to build a `KEY=` lookup), and every field with its FORM type.

> Each file section carries an `<a id="…">` anchor (its file name). For cheap per-file
> retrieval, `data-model-index.json` maps every file to its 1-based inclusive line range —
> load just that slice instead of the whole document. Regenerate the index with
> `tools/gen_datamodel_index.exe` after (re)generating or hand-editing this file.

| File | Recl | Fields | Keys |
|---|---|---|---|
| [`emailcfg.lay`](#emailcfg.lay) | ? | 4 | 0 |
| [`inventory.lay`](#inventory.lay) | ? | 20 | 4 |
| [`invoice.lay`](#invoice.lay) | ? | 15 | 3 |
| [`payment.lay`](#payment.lay) | ? | 6 | 2 |
| [`purchase.lay`](#purchase.lay) | ? | 9 | 2 |
| [`sales.lay`](#sales.lay) | ? | 10 | 2 |
| [`screenfld.lay`](#screenfld.lay) | ? | 27 | 2 |
| [`screenio.lay`](#screenio.lay) | ? | 51 | 1 |
| [`storecfg.lay`](#storecfg.lay) | ? | 9 | 0 |

<a id="emailcfg.lay"></a>
## emailcfg.lay

- **Data file:** `emailcfg.dat` (field prefix `conf_`) · **recl** ?

| Field | Type | Pos | Description |
|---|---|---|---|
| `SERVER$` | V 255 | — | Server |
| `FROMADDR$` | V 255 | — | From Address |
| `USERACCOUNT$` | V 120 | — | User Account |
| `PASSWORD$` | V 120 | — | Password |

<a id="inventory.lay"></a>
## inventory.lay

- **Data file:** `data\inventory.dat` (field prefix `IN_`) · **recl** ?
- **Keys:**
  - `key` (`data\inventory.key`) = `ITEMID`
  - `ky2` (`data\inventory.ky2`) = `DESCRIPTION-U`
  - `ky3` (`data\inventory.ky3`) = `CATEGORY-U` + `ITEMID`
  - `ky4` (`data\inventory.ky4`) = `UPC`

| Field | Type | Pos | Description |
|---|---|---|---|
| `ITEMID$` | C 8 | 1-8 | Item Number |
| `UPC$` | C 14 | 9-22 | UPC or Barcode |
| `ITEMTYPE$` | C 1 | 23-23 | Type: C=Clock P=Part S=Service |
| `DESCRIPTION$` | V 60 | 24-83 | Description |
| `CATEGORY$` | C 12 | 84-95 | Category (Mantel Wall Tall Case etc) |
| `MAKER$` | V 30 | 96-125 | Maker |
| `ORIGIN$` | V 20 | 126-145 | Country of Origin |
| `ERA$` | V 12 | 146-157 | Era or Year Made |
| `CONDITION$` | C 10 | 158-167 | Condition |
| `SERIALNO$` | V 20 | 168-187 | Serial Number |
| `LOCATION$` | V 20 | 188-207 | Display Location |
| `COST` | PD 6.2 | 208-213 | Unit Cost |
| `PRICE` | PD 6.2 | 214-219 | Retail Price |
| `QTYONHAND` | PD 4 | 220-223 | Quantity on Hand |
| `MAXPERSALE` | PD 4 | 224-227 | Most per Sale (0 means no limit) |
| `TAXABLE$` | C 1 | 228-228 | Taxable (Y/N) |
| `STATUS$` | C 1 | 229-229 | Status: A=Active H=Hold I=Inactive |
| `DATEADDED` | BH 3 | 230-232 | Date Added _(DATE(Julian))_ |
| `LASTSOLD` | BH 3 | 233-235 | Date Last Sold _(DATE(Julian))_ |
| `NOTES$` | V 255 | 236-490 | Notes and Provenance |

<a id="invoice.lay"></a>
## invoice.lay

- **Data file:** `data\invoice.dat` (field prefix `IV_`) · **recl** ?
- **Keys:**
  - `key` (`data\invoice.key`) = `INVOICENO`
  - `ky2` (`data\invoice.ky2`) = `INVDATE` + `INVOICENO`
  - `ky3` (`data\invoice.ky3`) = `CUSTNAME-U`

| Field | Type | Pos | Description |
|---|---|---|---|
| `INVOICENO$` | C 8 | 1-8 | Invoice Number |
| `INVDATE` | BH 3 | 9-11 | Invoice Date _(DATE(Julian))_ |
| `INVTIME$` | C 8 | 12-19 | Invoice Time |
| `CLERK$` | V 20 | 20-39 | Sales Clerk |
| `CUSTNAME$` | V 40 | 40-79 | Customer Name |
| `CUSTPHONE$` | V 20 | 80-99 | Customer Phone |
| `SUBTOTAL` | PD 6.2 | 100-105 | Subtotal |
| `DISCOUNT` | PD 6.2 | 106-111 | Discount |
| `TAXRATE` | PD 4.4 | 112-115 | Tax Rate |
| `TAXAMT` | PD 6.2 | 116-121 | Sales Tax |
| `TOTAL` | PD 6.2 | 122-127 | Invoice Total |
| `AMTPAID` | PD 6.2 | 128-133 | Amount Tendered |
| `CHANGEDUE` | PD 6.2 | 134-139 | Change Given |
| `STATUS$` | C 1 | 140-140 | Status: O=Open P=Paid V=Void |
| `NOTES$` | V 255 | 141-395 | Notes |

<a id="payment.lay"></a>
## payment.lay

- **Data file:** `data\payment.dat` (field prefix `PY_`) · **recl** ?
- **Keys:**
  - `key` (`data\payment.key`) = `INVOICENO` + `SEQ`
  - `ky2` (`data\payment.ky2`) = `PAYDATE` + `METHOD`

| Field | Type | Pos | Description |
|---|---|---|---|
| `INVOICENO$` | C 8 | 1-8 | Invoice Number |
| `SEQ` | BH 1 | 9-9 | Payment Sequence |
| `PAYDATE` | BH 3 | 10-12 | Payment Date _(DATE(Julian))_ |
| `METHOD$` | C 6 | 13-18 | Method: CASH CHECK CARD |
| `AMOUNT` | PD 6.2 | 19-24 | Amount Applied |
| `REFERENCE$` | V 30 | 25-54 | Check Number or Card Auth |

<a id="purchase.lay"></a>
## purchase.lay

- **Data file:** `data\purchase.dat` (field prefix `PU_`) · **recl** ?
- **Keys:**
  - `key` (`data\purchase.key`) = `PURCHASEID`
  - `ky2` (`data\purchase.ky2`) = `ITEMID` + `PURCHDATE`

| Field | Type | Pos | Description |
|---|---|---|---|
| `PURCHASEID$` | C 8 | 1-8 | Purchase Number |
| `ITEMID$` | C 8 | 9-16 | Item Number |
| `PURCHDATE` | BH 3 | 17-19 | Date Purchased _(DATE(Julian))_ |
| `SOURCE$` | V 40 | 20-59 | Bought From (dealer estate auction) |
| `SOURCEINFO$` | V 60 | 60-119 | Seller Contact |
| `QTY` | PD 4 | 120-123 | Quantity |
| `UNITCOST` | PD 6.2 | 124-129 | Unit Cost |
| `TOTALCOST` | PD 6.2 | 130-135 | Total Cost |
| `NOTES$` | V 255 | 136-390 | Notes |

<a id="sales.lay"></a>
## sales.lay

- **Data file:** `data\sales.dat` (field prefix `SL_`) · **recl** ?
- **Keys:**
  - `key` (`data\sales.key`) = `INVOICENO` + `LINENO`
  - `ky2` (`data\sales.ky2`) = `ITEMID` + `SALEDATE`

| Field | Type | Pos | Description |
|---|---|---|---|
| `INVOICENO$` | C 8 | 1-8 | Invoice Number |
| `LINENO` | BH 2 | 9-10 | Line Number |
| `ITEMID$` | C 8 | 11-18 | Item Number |
| `DESCRIPTION$` | V 60 | 19-78 | Description as Sold |
| `QTY` | PD 5.2 | 79-83 | Quantity (hours for labor) |
| `UNITPRICE` | PD 6.2 | 84-89 | Unit Price |
| `DISCOUNT` | PD 6.2 | 90-95 | Line Discount |
| `EXTENDED` | PD 6.2 | 96-101 | Extended Amount |
| `TAXABLE$` | C 1 | 102-102 | Taxable (Y/N) |
| `SALEDATE` | BH 3 | 103-105 | Sale Date _(DATE(Julian))_ |

<a id="screenfld.lay"></a>
## screenfld.lay

- **Data file:** `screen\screenfld.dat` (field prefix `SF_`) · **recl** ?
- **Keys:**
  - `key` (`screen\screenfld.key`) = `SCREENCODE`
  - `ky2` (`screen\screenfld.ky2`) = `SCREENCODE` + `CONTROLNAME`

| Field | Type | Pos | Description |
|---|---|---|---|
| `SCREENCODE$` | V 18 | — | Screen Code |
| `CONTROLNAME$` | V 50 | — | Control Name |
| `FIELDNAME$` | V 50 | — | Field Name from File Layout |
| `DESCRIPTION$` | V 255 | — | Caption or Caption Field |
| `VPOSITION` | B 1 | — | Vertical Position |
| `HPOSITION` | BH 2 | — | Horizontal Position |
| `FIELDTYPE$` | V 8 | — | Field Type Code |
| `SPECWIDTH` | BH 2 | — | Spec Width |
| `WIDTH` | BH 2 | — | Width |
| `HEIGHT` | B 1 | — | Height |
| `TRUEVALUE$` | V 60 | — | Value if True |
| `FALSEVALUE$` | V 60 | — | Value if False |
| `FUNCTION$` | V 255 | — | Function or Validation |
| `PICTURE$` | V 255 | — | Picture File |
| `PARENT$` | V 20 | — | Parent Control for Listchld |
| `FGCOLOR$` | C 6 | — | Foreground Color |
| `BGCOLOR$` | C 6 | — | Background Color |
| `JUSTIFY$` | C 1 | — | L R C U or blank |
| `ATTR$` | V 128 | — | Field Attributes |
| `PROTECTED` | B 1 | — | Protected Flag |
| `INVISIBLE` | B 1 | — | Invisible Flag |
| `TOOLTIP$` | V 1000 | — | Tooltip Text |
| `CNVRTIN$` | V 255 | — | Incoming Conversion |
| `CNVRTOUT$` | V 255 | — | Outgoing Conversion |
| `MULTISELECT` | B 1 | — | MultiSelect |
| `USERDATA$` | V 255 | — | Custom Data |
| `GRIDLINES` | B 1 | — | Gridlines for Listviews |

<a id="screenio.lay"></a>
## screenio.lay

- **Data file:** `screen\screenio.dat` (field prefix `SI_`) · **recl** ?
- **Keys:**
  - `key` (`screen\screenio.key`) = `SCREENCODE`

| Field | Type | Pos | Description |
|---|---|---|---|
| `SCREENCODE$` | V 18 | — | Screen Code |
| `CAPTION$` | V 60 | — | Caption |
| `VSIZE` | B 1 | — | V Size |
| `HSIZE` | BH 2 | — | H Size |
| `ATTRIBUTES$` | V 255 | — | Screen Attributes |
| `PICTURE$` | V 60 | — | Background Picture File |
| `FGCOLOR$` | C 6 | — | Foreground Color |
| `BGCOLOR$` | C 6 | — | Background Color |
| `FILELAY$` | V 18 | — | File Layout for Screen |
| `PROJECT$` | V 255 | — | Project |
| `NOTES$` | V 255 | — | Notes |
| `ENTERFN$` | V 255 | — | Enter |
| `INITFN$` | V 255 | — | Initialize |
| `READFN$` | V 255 | — | Read |
| `LOADFN$` | V 255 | — | Load |
| `WRITEFN$` | V 255 | — | Write |
| `WAITFN$` | V 255 | — | Wait |
| `LOCKEDFN$` | V 255 | — | Record Locked |
| `MERGEFN$` | V 255 | — | Merge Function |
| `LOOPFN$` | V 255 | — | Main Loop |
| `NOKEYFN$` | V 255 | — | Nokey |
| `PRELISTVIEWFN$` | V 255 | — | Listview Prepopulate |
| `POSTLISTVIEWFN$` | V 255 | — | Listview Postpopulate |
| `EXITFN$` | V 255 | — | Exit |
| `BORDER` | B 1 | — | Window Border |
| `WINDCAP$` | V 80 | — | Window Caption |
| `WAITTIME` | BH 2 | — | Wait Time -1 for disable |
| `INPUTATTR$` | V 255 | — | Input Attributes |
| `CREATEDATE` | BH 3 | — | Date Created |
| `MODIFYDATE` | BH 3 | — | Date Modified |
| `CREATEUSER$` | V 30 | — | User who Created |
| `MODIFYUSER$` | V 30 | — | Last User who Modified |
| `READINDEX` | B 1 | — | Index to use when reading |
| `RETURNINDEX` | B 1 | — | Index to use when returning |
| `DEBUGSCREEN$` | V 64 | — | Test call for your screen |
| `DEBUGKEY$` | V 255 | — | Test Key$ |
| `DEBUGPARENTKEY$` | V 255 | — | Test Parent Key$ |
| `DEBUGRECORD` | BH 3 | — | Test Record Number |
| `DEBUGPATH$` | V 255 | — | Test Path$ |
| `DEBUGPASSED$` | V 255 | — | Test Mat Passed Data |
| `PROTECTEDTEXT$` | V 255 | — | Protected Attribute for Text |
| `PROTECTEDCHECK$` | V 255 | — | Protected Attribute for Check Boxes |
| `PROTECTEDBUTTON$` | V 255 | — | Protected Attribute for Buttons |
| `SCREENIOLOCKING` | B 1 | — | Use ScreenIO Locking |
| `SCREENIOMERGE` | B 1 | — | Use ScreenIO AutoMerge |
| `OTHERCHANGES$` | V 255 | — | Attribute for Others Changes |
| `MYCHANGES$` | V 255 | — | Attribute for My Changes |
| `LOCKWINDOW$` | V 255 | — | Attribute for Lock Window Color |
| `ACTIVECOLOR$` | V 255 | — | Active Color for Window |
| `USERDATA$` | V 255 | — | Userdata array for use in functions |
| `VERSION` | BH 4 | — | Current Version of Screen |

<a id="storecfg.lay"></a>
## storecfg.lay

- **Data file:** `data\storecfg.dat` (field prefix `CF_`) · **recl** ?

| Field | Type | Pos | Description |
|---|---|---|---|
| `STORENAME$` | V 40 | 1-40 | Store Name |
| `ADDRESS1$` | V 40 | 41-80 | Address Line 1 |
| `ADDRESS2$` | V 40 | 81-120 | Address Line 2 |
| `CITYSTZIP$` | V 60 | 121-180 | City State Zip |
| `PHONE$` | V 20 | 181-200 | Store Phone |
| `TAXRATE` | PD 4.4 | 201-204 | Sales Tax Rate (0.0825 = 8.25%) |
| `NEXTINVOICE` | PD 6 | 205-210 | Next Invoice Number |
| `NEXTPURCHASE` | PD 6 | 211-216 | Next Purchase Number |
| `RECEIPTMSG$` | V 80 | 217-296 | Receipt Footer Message |
