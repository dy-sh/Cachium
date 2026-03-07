# New Features Log

## 2026-03-07
- **Multi-Currency Bug Fixes and Robustness**: Transfer transactions are now correctly reversed when deleting by category or moving to another account; cross-currency account moves use live exchange rates for amount conversion; editing only the destination amount on a transfer now properly enables the save button; currency conversion helpers round to 2 decimal places to prevent floating-point accumulation errors; a stale-rates warning icon appears on the Total Balance card when exchange rates are more than 24 hours old and multiple account currencies are in use (`exchangeRatesStaleProvider`).
- **Cross-Currency Transfer Destination Amount**: Adds a `destinationAmount` field to the Transaction model so cross-currency transfers store the credited amount separately; the transaction form shows an editable destination amount field when source and destination accounts differ in currency.
- **Exchange Rate API Selection**: `ExchangeRatesNotifier` now correctly wires the chosen API implementation from settings before fetching; the previously broken ExchangeRate.host provider is replaced with Open ER-API (`open.er-api.com`), which is free and requires no API key.
- **Rate Staleness Indicator**: The formats settings screen displays "Rates as of: X" with a staleness indicator and a manual refresh button; fetches are automatically skipped if rates were updated less than 24 hours ago (`lastRateFetchTimestamp` persisted in AppSettings).
- **Manual Exchange Rate Editor**: New screen at `/settings/formats/manual-rates` lets users add currencies and enter custom exchange rates when Manual mode is selected, bypassing external APIs entirely.

## 2026-03-06
- **Multi-Currency Support**: Accounts and transactions store their own currency codes; exchange rates are eagerly loaded and refreshed on save; all balance displays use the correct per-account or per-transaction currency; foreign-currency items show a main-currency equivalent ("≈ $X,XXX.XX") subtitle on account detail, account cards, account preview list, and transaction detail screens.
