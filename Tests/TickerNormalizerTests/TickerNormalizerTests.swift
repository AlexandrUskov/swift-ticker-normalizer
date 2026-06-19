import Testing
@testable import TickerNormalizer

@Suite("TickerNormalizer")
struct TickerNormalizerTests {

    // MARK: - Common spot / perp formats

    @Test("Binance BTCUSDT → BTC")
    func binance() { #expect(TickerNormalizer.sanitize("BTCUSDT") == "BTC") }

    @Test("Slash pair BTC/USDT → BTC")
    func slashPair() { #expect(TickerNormalizer.sanitize("BTC/USDT") == "BTC") }

    @Test("Lowercase with dash sol-perp → SOL")
    func dashPerp() { #expect(TickerNormalizer.sanitize("sol-perp") == "SOL") }

    @Test("Already canonical BTC → BTC")
    func passthrough() { #expect(TickerNormalizer.sanitize("BTC") == "BTC") }

    // MARK: - OKX

    @Test("OKX BTC-USDT-SWAP → BTC")
    func okxBTC() { #expect(TickerNormalizer.sanitize("BTC-USDT-SWAP") == "BTC") }

    @Test("OKX ETH-USDC-SWAP → ETH")
    func okxETH() { #expect(TickerNormalizer.sanitize("ETH-USDC-SWAP") == "ETH") }

    // MARK: - KuCoin (XBT alias)

    @Test("KuCoin XBTUSDTM → BTC")
    func kucoinBTC() { #expect(TickerNormalizer.sanitize("XBTUSDTM") == "BTC") }

    @Test("KuCoin ETHUSDTM → ETH")
    func kucoinETH() { #expect(TickerNormalizer.sanitize("ETHUSDTM") == "ETH") }

    // MARK: - Kraken futures prefixes

    @Test("Kraken PF_XBTUSD → BTC")
    func krakenPF() { #expect(TickerNormalizer.sanitize("PF_XBTUSD") == "BTC") }

    @Test("Kraken FI_XBTUSD → BTC (inverse futures)")
    func krakenFI() { #expect(TickerNormalizer.sanitize("FI_XBTUSD") == "BTC") }

    @Test("Kraken PF_ETHUSD → ETH")
    func krakenETH() { #expect(TickerNormalizer.sanitize("PF_ETHUSD") == "ETH") }

    // MARK: - Bitfinex (t-prefix + positional suffix)

    @Test("Bitfinex tBTCF0:USTF0 → BTC")
    func bitfinexBTC() { #expect(TickerNormalizer.sanitize("tBTCF0:USTF0") == "BTC") }

    @Test("Bitfinex tETHF0:USTF0 → ETH")
    func bitfinexETH() { #expect(TickerNormalizer.sanitize("tETHF0:USTF0") == "ETH") }

    @Test("Bitfinex BTC-margined tBTCF0:BTCF0 → BTC")
    func bitfinexBTCmargined() { #expect(TickerNormalizer.sanitize("tBTCF0:BTCF0") == "BTC") }

    // MARK: - Aliases

    @Test("Standalone XBT → BTC")
    func xbtAlias() { #expect(TickerNormalizer.sanitize("XBT") == "BTC") }

    @Test("XBTUSDT → BTC")
    func xbtWithSuffix() { #expect(TickerNormalizer.sanitize("XBTUSDT") == "BTC") }

    // MARK: - Guards & edge cases

    @Test("'test' is NOT t-stripped (lowercase follows) → TEST")
    func notStrippedForWord() { #expect(TickerNormalizer.sanitize("test") == "TEST") }

    @Test("Single 't' → T")
    func singleT() { #expect(TickerNormalizer.sanitize("t") == "T") }

    @Test("Empty string → empty")
    func empty() { #expect(TickerNormalizer.sanitize("") == "") }

    @Test("A bare suffix is not collapsed to empty: USDT → USDT")
    func bareSuffix() { #expect(TickerNormalizer.sanitize("USDT") == "USDT") }

    @Test("Whitespace is trimmed: '  btc/usdt  ' → BTC")
    func whitespace() { #expect(TickerNormalizer.sanitize("  btc/usdt  ") == "BTC") }

    // MARK: - The headline guarantee

    @Test("Cross-exchange consistency — every BTC perp format normalizes to BTC")
    func crossExchangeBTC() {
        let inputs = [
            "BTCUSDT",        // Binance / Bybit / Bitget
            "BTC-USDT-SWAP",  // OKX
            "BTC_USDT",       // MEXC / Gate.io
            "BTC-PERP-INTX",  // Coinbase
            "XBTUSDTM",       // KuCoin
            "BTC-USDT",       // BingX
            "PF_XBTUSD",      // Kraken
            "tBTCF0:USTF0",   // Bitfinex
        ]
        for input in inputs {
            #expect(TickerNormalizer.sanitize(input) == "BTC", "failed for: \(input)")
        }
    }
}
