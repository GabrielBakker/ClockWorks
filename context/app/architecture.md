---
title: ClockWorks — architecture
file: architecture.md
category: app
description: Module map, screens, event functions, data flows and design decisions for ClockWorks, a training POS app for an antique clock store that also bills repairs.
---

# ClockWorks architecture

ClockWorks is a **training exercise**: a point-of-sale system for a made-up antique clock store
that also bills clock repairs. Built from scratch on Lexi + FileIO + ScreenIO; house style is in
[`conventions.md`](conventions.md), data layouts in [`data-model.md`](data-model.md).

## Programs

| Program | Kind | Role |
|---|---|---|
| `start.brs` | entry point | Run by `brconfig.sys` (`execute "run start"`). Sizes window #0 (27 x 100) and opens three tabs through `run.brs`'s `fnRunTabs`: **Sales** (REGISTER), **Purchases** (PURCHASES), **Inventory** (INVENTORY). Esc is blocked; closing the window with its X (fkey 93) closes BR (`execute "System"`) |
| `makescreens.brs` | utility | **The screens' source.** Writes every screen's `screenio.dat`/`screenfld.dat` records through FileIO and compiles them with `fnCompileScreen`. Rerunnable: each screen's records are deleted and rewritten. Change a screen here, then run it headlessly |
| `printlib.brs` | library | Receipts and reports: `fnAfterSale` (offers a receipt for a completed sale), `fnPrintReceipt` (42-column register receipt), `fnPrintDayReport` (end of day). Print to `PREVIEW:/DEFAULT`, or to a file name for testing |
| `initfiles.brs` | utility | Opens every layout through FileIO, creating or upgrading each data file |
| `seeddata.brs` | utility | Loads the training sample data into an empty system |

`run.brs`, `fileio.brs`, `screenio.brs` and `lexi.brs` are the shipped libraries, not app code.

## Screens

ScreenIO allows one listview per screen, so each list lives on its own screen.

| Screen | File | Size | Opened by | Role |
|---|---|---|---|---|
| **REGISTER** | `invoice` | 24 x 96, no border | Sales tab | The cash register: item box with magnifier, customer name and phone, the SALELINES child, totals, Pay / Complete Sale / Void Sale / Day Report |
| **SALELINES** | `sales` | 10 x 90, no border | child `screen` control on REGISTER | The sale's lines; Change Qty and Remove Line |
| **QTYEDIT** | `sales` | 8 x 62 | SALELINES' Change Qty | Change one line's quantity |
| **ITEMSEARCH** | `inventory` | 22 x 92 | REGISTER's and BUY's magnifiers | Item picker with a filter box; `ParentKey$` "RESTOCK" changes what it lists |
| **TENDER** | `payment` | 19 x 70 | REGISTER's Pay | Take payments: Cash / Check / Card, list of payments, Remove Payment, Done |
| **PURCHASES** | `purchase` | 24 x 96, no border | Purchases tab | Every purchase, newest first, with a filter box; New Purchase |
| **BUY** | `purchase` | 23 x 90 | PURCHASES' New Purchase | One purchase: a restock of an existing item, or a new item's details |
| **INVENTORY** | `inventory` | 24 x 96, no border | Inventory tab | Every item with On Hand, price, cost, status; Edit Item / Add Item |
| **INVEDIT** | `inventory` | 17 x 84 | INVENTORY's buttons | Add or edit one inventory item |

**Tab screens** (REGISTER, PURCHASES, INVENTORY) are all 24 x 96 with `BORDER=0`: each runs at
1,1 of a tab window its own size, and window #0 must be at least 2 rows and 2 columns bigger
(`screenio-guide.md`, "Hosting several screens as tabs").

**Colors** (house rule: a called screen is darker than its caller, `conventions.md` §9): tab
screens walnut `6B4423`; screens they call `50331A`; QTYEDIT (called from SALELINES) `3C2614`,
which is also window #0's background. Headers use `FGCOLOR` `FFFFFF`, so captions (blank colors)
are white; text boxes, buttons and listviews use `"W"`.

## Event functions (`function/`)

| Screen | Event | Function | Does |
|---|---|---|---|
| REGISTER | Enter / Exit | `registerenter` / `registerexit` | Open (all OutIn) / close inventory (by item and UPC), sales, payment, storecfg. Exit also offers the receipt after a completed sale |
| REGISTER | Main Loop | `registermainloop` | Re-totals an open sale every pass; guards the window X while a sale is open (tab clicks are left to the Write event) |
| REGISTER | Write | `registerwrite` | Tab click: with no sale, leave without writing; with a sale, ask (payments taken: refuse); cancelling keeps fkey 92 so ScreenIO switches the tab back |
| REGISTER | item box Validate | `additemtosale` | Rings up an item number or UPC, with an optional `qty*` prefix; `fnRingUpItem`, `fnStartInvoice`, `fnTotalSale` |
| REGISTER | buttons | `searchinventory`, `paysale`, `completesale`, `voidsale`, `dayreport` | Magnifier, Pay, Complete Sale, Void Sale, Day Report |
| SALELINES | Filter / button | `salelinesfilter` / `removesaleline` | This invoice's lines / Remove Line |
| QTYEDIT | Validate / Write | `validatesaleqty` / `writesaleqty` | Check the quantity / recompute the line amount |
| ITEMSEARCH | Filter | `itemsearchfilter` | Selling: active and in stock (services always). RESTOCK: every active clock and part |
| TENDER | Enter / Exit / Main Loop / Filter | `tenderenter` / `tenderexit` / `tendermainloop` / `tenderfilter` | Totals from `PassedData$(1)`; Main Loop cancels Enter so the listview screen doesn't select-and-quit |
| TENDER | buttons | `paycash`, `paycheck`, `paycard` (all `applypayment`), `removepayment` | Apply or remove a payment |
| PURCHASES | Filter | `purchasesfilter` | Every purchase; item descriptions looked up once per refresh (`fnInit_`/`fnFinal_`) |
| BUY | Enter / Exit / Initialize / Write | `buyenter` / `buyexit` / `buyinit` / `writepurchase` | Open/close files; defaults (today, qty 1, type C, taxable); number the purchase and add or restock the item |
| BUY | Validate / buttons | `validatebuyitem`, `validatebuytype`, `buysearch`, `savepurchase` | Restock item #, type C/P, magnifier, Save (required and new-or-restock checks) |
| INVEDIT | Initialize / Write / Save | `initinvitem` / `writeinvitem` / `saveinvitem` | Defaults (type C, active, taxable, today); number a new item; Save (required checks) |
| INVEDIT | Validate | `validateitemtype`, `validateitemstatus` | Type C/P/S and Status A/H/I, with `AEX` |

**Shared helpers:** `saleqtyrules` (`fnSaleQtyOk`, the quantity rules for the item box and
Change Qty); `nextinvid` (`fnNextInvId$`, the next CLK/PRT/SVC number for BUY and INVEDIT; takes
the caller's FileIO-sized arrays); and the reusable validators `validatenotblank`,
`validatenotnegative`, `validatewholenumber`, `validatequantity`.

The other files in `function/` are ScreenIO's stock functions, unused so far.

## Data files

| File | Holds |
|---|---|
| `inventory` | Clocks (`C`), parts (`P`) and repair services (`S`, never stocked). On hand, price, cost, most per sale (0 = no limit), status A/H/I, taxable Y/N |
| `purchase` | Clocks and parts the store bought: seller, date, quantity, unit and total cost |
| `invoice` | One header per sale; status `O` open (in memory only), `P` paid, `V` void |
| `sales` | One line per item sold, with the description and price as sold; quantity has two decimals (labor hours) |
| `payment` | Payments applied to an invoice; several per invoice for split tender |
| `storecfg` | One record: store name and address, tax rate, next invoice and purchase numbers, receipt footer |

## Flows

**A sale (Sales tab).**
1. *First item:* the next invoice number comes from `storecfg`, and REGISTER's invoice fields are
   filled in (status `O`). The header is only written when the sale is completed or voided.
2. *Each item:* typed or scanned into the item box, optionally `qty*item`. Checked by
   `fnSaleQtyOk`: more than zero, two decimals, whole for clocks and parts, within stock and
   most-per-sale, not sold out. Written as a `sales` line; SALELINES is redrawn only when a line
   was added.
3. *Lines:* Change Qty (QTYEDIT) and Remove Line inside SALELINES; REGISTER's Main Loop re-totals.
4. *Pay:* TENDER writes `payment` records. Check and card need a reference and can't exceed the
   balance; cash can, for change.
5. *Complete Sale* (balance zero or less): clocks and parts leave stock (on hand down, last sold
   set), change is recorded, status `P`, `SaveAndQuit`. The Exit event offers the receipt;
   `run.brs` reopens REGISTER for the next sale.
6. *Void Sale:* status `V`, saved; lines and payments stay as the audit trail.
7. *Leaving mid-sale* (window X or a tab click): without payments, ask and on Yes delete the lines
   and hand the invoice number back; with payments, refuse.

**A purchase (Purchases tab → New Purchase).** Either a *restock* (an existing clock or part:
quantity up, cost set to the latest unit cost) or a *new item* (added to inventory as the next
CLKnnnn or PRTnnnn). The purchase gets the next purchase number. Services can't be purchased.

**Inventory maintenance (Inventory tab).** Edit any item's details, including On Hand for count
corrections, or add one (mainly services; new clocks and parts normally come in through
Purchases).

**Reports.** The receipt (after Complete Sale) and the Day Report button (today: invoices,
completed and voided totals, payments by method with net cash for the drawer, items sold).

## Decisions (owner)

- **No customer file.** Walk-in customers are many and random, and many don't want to be tracked;
  an invoice just has an optional name and phone.
- **Repairs are billed at the register** as service items; per-job services have Most per Sale 1,
  hourly labor takes fractional quantities. A repair-ticket file (intake, promised date, status,
  deposit) is wanted later.
- **Purchases** are clocks and parts the store buys for inventory; a restock takes the latest
  purchase price as the item's cost. The list is newest first.
- **Validation** happens field by field as it's typed; Save only checks required and cross-field
  rules (`screenio-guide.md`).
- **Test data** is kept; no reset utility is wanted.
