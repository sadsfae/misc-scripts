# Check Prices for Coins or Stocks

* coin_price.py (no API key needed, only crypto e.g. BTC)
* check_price.py (Polygon API key needed, checks stocks or crypto)

## Crypto Price Checker
Simple coin price alert application, loops a .WAV file when target is hit.

* Simple coin price checker
* Adjust `params = {'ids': 'bitcoin',` for other coins
* Uses coingecko simple API.

### Requires
* Python 3.x
* mplayer (or substitute your own audio player)

### Usage
`python coin_price.py below 85000 alert.wav`

`python coin_price.py above 85000 alert.wav`

## Stock Price Checker
Simple stock price checker, requires Polygon.io API key

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

still uses coingecko open API

`python check_price.py btc above 85000 alert.wav`
