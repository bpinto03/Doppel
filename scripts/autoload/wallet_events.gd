extends Node

## Carries the wallet signal: CoinWallet is static, like RecordBook, so it cannot emit one itself.

signal coins_changed(new_total: int)
