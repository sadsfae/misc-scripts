# Monitor Prices for Coins or Stocks
This contains (2) simple Python tools for monitoring stocks, crypto or both.

* coin_price.py (no API key needed, only crypto e.g. BTC)
  - cryptocurrencies only
  - monitors price targets (down or up)
  - monitors volatility e.g. 2% in 20min

* check_price.py (Polygon API key needed, checks stocks or crypto)
  - cryptocurrencies or stock tickers
  - monitors price targets only (down or up)

## Coin Price and Volatility Checker (coin_price.py)
Simple coin price alert application, loops a .WAV file when target is hit.

* Simple coin price and volatility tracker
* Uses coingecko simple API.

### Requires
* Python 3.x
* `python-requests`
* mplayer (or substitute your own audio player)

### Usage
#### Price Targets (above/below)
`python coin_price.py btc above 150000 alert.wav`

`python coin_price.py eth below 4000 alert.wav`

#### Volatility (percent-minutes)
* `vol 10-5` means more than 10% in 5minutes

`python coin_price.py sol vol 8-15 alert.wav`

`python coin_price.py doge vol 10-5 alert.wav`

## Stock and Coin Price Checker (check_price.py)
Simple stock and coin price checker, requires Polygon.io API key

### Requires
* Python 3.x
* `python-requests`
* Polygon API key (free) for stocks only
* mplayer (or substitute your own audio player)

### Setup
1) Go to https://polygon.io and sign up for a free account (no credit card needed).
2) Get your API key from the dashboard
3) Set it in your environment:

```bash
export POLYGON_API_KEY="your_actual_key_here"
```

### Usage
```
python check_price.py tsla above 400 alert.wav
python check_price.py ibm below 200 alert.wav
```

crypto prices still uses coingecko open API

`python check_price.py btc above 85000 alert.wav`
