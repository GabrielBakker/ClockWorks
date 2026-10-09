---
title: ClockWorks — architecture
file: architecture.md
category: app
description: Module map, data flows and design decisions for ClockWorks, a training POS app for an antique clock store that also bills repairs.
---

# ClockWorks architecture

ClockWorks is a **training exercise**: a point-of-sale system for a made-up antique clock store
that also bills clock repairs. Built from scratch on Lexi + FileIO + ScreenIO; house style is in
[`conventions.md`](conventions.md), data layouts in [`data-model.md`](data-model.md).

## Module map

| Program / screen | Kind | Role |
|---|---|---|
| `start.brs` | entry point | Launches the app: opens the REGISTER screen (to be added to `brconfig.sys` once it works) |
| `initfiles.brs` | utility | Opens every layout through FileIO, creating or upgrading each data file |
| `seeddata.brs` | utility | Loads the training sample data into an empty system |
| **REGISTER** | ScreenIO screen, file `invoice` | The cash register: item entry, customer name and phone, totals, Pay / Complete / Void / New / Exit |
| **SALELINES** | ScreenIO screen, file `sales` | Output-only listview of the current sale's lines, embedded in REGISTER as a child `screen` control. Clicking it activates Remove Line / Change Qty |
| **ITEMSEARCH** | ScreenIO screen, file `inventory` | Full inventory listview used as a picker by REGISTER's Search button; returns the selected item number |
| **TENDER** | ScreenIO screen, file `payment` | Payment entry with its own listview of payments applied; supports split tender |

ScreenIO allows only one listview per screen, so each list lives on its own screen.

## Data files

| File | Holds |
|---|---|
| `inventory` | Clocks (`C`), parts (`P`) and repair services (`S`). Services are never stocked |
| `purchase` | Clocks and parts the store bought for inventory (the acquisition process is to be designed later) |
| `invoice` | One header per sale; status `O` open, `P` paid, `V` void |
| `sales` | Sales history: one line per item sold, with the description and price as sold |
| `payment` | Payments applied to an invoice; several per invoice for split tender |
| `storecfg` | One record: store name and address, tax rate, next invoice and purchase numbers, receipt footer |

## The sale flow

1. **First item rung up:** take the next invoice number from `storecfg` and write an `invoice`
   header with status `O`.
2. **Each item:** the clerk types an item number or scans a barcode into the item box. Its
   **Validate** event looks the item up by item number, then by `UPC`. If it's found, active, and
   not already fully on this sale, it writes a `sales` line (quantity 1, current price) and sets
   `RedrawScreens=1` so SALELINES reloads. A failed lookup shows a `Msgbox` and **does not** redraw
   (redrawing child screens is slow). The box is cleared after a successful add. The Search button
   opens ITEMSEARCH and runs the chosen item number through the same path.
3. **SALELINES** gets the invoice number through its control's function text,
   `ParentKey$=F$(IV_INVOICENO)`, and its Filter shows only that invoice's lines.
4. **Pay…** opens TENDER: the clerk picks Cash, Check or Card, an amount (defaulting to the balance)
   and a reference, then clicks Apply. Each application writes a `payment` record.
5. **Complete Sale** (once the balance is zero or less): status becomes `P`, change due is shown,
   and each clock or part line lowers `QTYONHAND` and sets `LASTSOLD`. **Inventory changes only
   here.** Service lines never touch stock. The screen then resets to a new sale.
6. **Void** marks an open invoice `V` and keeps its lines for the audit trail. No inventory was
   changed, so there's nothing to undo.

## Screen colors

House rule (called screens darker, see `conventions.md` §9): REGISTER uses walnut brown `6B4423`
with white caption text (`FGCOLOR` `FFFFFF`); SALELINES, ITEMSEARCH and TENDER use `50331A` (about 75% as bright).

## Decisions so far (owner, 2026-10-09)

- **No customer file.** Walk-in customers are many and random, and many don't want to be tracked;
  an invoice just has an optional name and phone.
- **Repairs are billed at the register** as service items. A repair-ticket file (intake, promised
  date, status, deposit) is wanted later, but not in the first iteration.
- **"Clock purchase history"** means clocks the store buys for inventory. That process is to be
  designed later.
- **Receipt printing** comes in a later iteration, using `storecfg`'s receipt footer.
