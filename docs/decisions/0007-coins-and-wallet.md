# 0007 — Coins and wallet

**Status:** accepted (2026-11-01)

## Context

A finished game pays coins into a wallet kept in the save. Paying and erasing the finished game are two save changes. Android can kill the app at any time: if only one of them reached the disk, the game would pay twice (coins written, game still saved and replayed) or never (game erased, coins lost).

## Decision

- `CoinWallet` is static, like `RecordBook`, in the `wallet` save section. Its `coins_changed` signal lives on a small autoload, `WalletEvents`, since a static class cannot emit.
- The reward is paid in `GameScreen._save_turn()`, right after `play_column()` of the turn that ends the game and before the playback: record, then `add_coins()`, then `CurrentGameStore.erase()`.
- These changes are made in the same frame, with no `flush()` between them, so `SaveManager` writes them together in its end-of-frame write ([0005](0005-save-writing.md)). No "reward paid" flag is stored.
- The balance reads a negative or non-integer value as 0. No save migration: a missing section is an empty wallet.

## Consequences

- A kill before that write keeps neither change: the saved game resumes before its last turn, and playing it again pays once.
- A kill during the write leaves the old or the new save (temporary file, then backup), never half of it.
- Code that calls `SaveManager.flush()` between the payment and the erase would break this; keep them together in `_save_turn()`.
