# ZigCoin

A fast and minimal CLI cryptocurrency information tool written in Zig, using the CoinGecko API v3.

## Features

- Fetch real-time cryptocurrency price data
- Display market information including:
  - Current price
  - Market cap
  - 24h volume
  - Price changes
  - Supply information
- Clean and colorful CLI output
- Zero configuration needed

## Prerequisites

- Zig 0.11.0 or later
- libcurl development files

### Installing Dependencies

#### Ubuntu/Debian

```bash
sudo apt-get install libcurl4-openssl-dev
```

#### macOS

```bash
brew install curl
```

## Building

```bash
zig build
```

## Running

```bash
./zig-out/bin/zigcoin bitcoin
```

## Example Output

```
Bitcoin (BTC)
=============
Price: $45,000.00
Market Cap: $800,000,000,000.00
24h Volume: $24,000,000,000.00
24h Change: 2.50%
Market Cap Rank: #1

Supply
======
Circulating: 19,000,000
Total: 21,000,000
Max: 21,000,000

Last Updated: 2024-01-01T00:00:00Z
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- CoinGecko API for providing the cryptocurrency data
- Zig community for the amazing programming language
