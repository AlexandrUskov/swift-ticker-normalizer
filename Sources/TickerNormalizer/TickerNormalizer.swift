import Foundation

/// Canonicalizes exchange ticker symbols to a single comparable form, so the same
/// asset arriving from different exchanges (in wildly different formats) deduplicates cleanly.
///
/// The problem: eleven exchanges express "Bitcoin perpetual" eleven different ways —
/// `BTCUSDT` (Binance), `BTC-USDT-SWAP` (OKX), `XBTUSDTM` (KuCoin), `PF_XBTUSD` (Kraken),
/// `tBTCF0:USTF0` (Bitfinex), `BTC-PERP-INTX` (Coinbase)… `sanitize` maps all of them to `BTC`.
///
/// Pipeline:
/// 1. strip a leading Bitfinex `t` (only when an uppercase symbol follows, so `test` stays `TEST`)
/// 2. remove separators `/ - _ :`
/// 3. uppercase
/// 4. strip a leading Kraken futures prefix (`PF` `PI` `FI` `FF`)
/// 5. strip a trailing quote/contract suffix (longest-first, so `BTCUSDT` → `BTC`, never `BTCUS`)
/// 6. remap legacy base-currency aliases (`XBT` → `BTC`)
public enum TickerNormalizer {

    /// Trailing suffixes to strip, ordered **longest-first**.
    ///
    /// Order matters: `USDT` must come before `USD` so `BTCUSDT` → `BTC` (not `BTCUS`);
    /// `USDTSWAP`/`USDTM` come before `USDT` for OKX/KuCoin; `F0USTF0`/`F0BTCF0` cover Bitfinex
    /// perpetuals (`tBTCF0:USTF0` → … → `BTCF0USTF0` → `BTC`).
    private static let suffixes = [
        "F0USTF0", "F0BTCF0", "PERPINTX", "USDTSWAP", "USDCSWAP",
        "USDTM", "USDCM", "USDT", "USDC", "BUSD", "USD", "PERP",
    ]

    /// Base-currency aliases applied **after** suffix stripping.
    /// KuCoin/Kraken use the legacy `XBT` for Bitcoin.
    private static let aliases: [String: String] = [
        "XBT": "BTC",
    ]

    /// Returns the canonical symbol for any exchange ticker or user input.
    ///
    /// A guard (`count > suffix.count`) keeps a string that *is* a suffix from collapsing to
    /// empty — `sanitize("USDT") == "USDT"`, not `""`.
    ///
    /// - Parameter raw: ticker from an exchange API, a CSV, or user input — any format.
    /// - Returns: the normalized symbol, e.g. `"BTC"`.
    public static func sanitize(_ raw: String) -> String {
        // Step 1 — strip a leading Bitfinex "t" (lowercase t before an uppercase symbol).
        // Done before uppercasing so the case boundary is still visible.
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("t"), cleaned.count > 1 {
            let secondIndex = cleaned.index(after: cleaned.startIndex)
            if cleaned[secondIndex].isUppercase {
                cleaned.removeFirst()
            }
        }

        // Steps 2–3 — remove separators and uppercase.
        var result = cleaned
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ":", with: "")
            .uppercased()

        // Step 4 — strip a Kraken futures prefix (PF_XBTUSD → XBTUSD → … → BTC).
        for prefix in ["PF", "PI", "FI", "FF"] {
            if result.hasPrefix(prefix), result.count > prefix.count {
                result = String(result.dropFirst(prefix.count))
                break
            }
        }

        // Step 5 — strip a trailing quote/contract suffix (longest-first).
        for suffix in suffixes {
            if result.hasSuffix(suffix), result.count > suffix.count {
                result = String(result.dropLast(suffix.count))
                break
            }
        }

        // Step 6 — remap legacy aliases.
        if let alias = aliases[result] {
            result = alias
        }

        return result
    }
}
