# Price Alert

Monitors crypto/stock prices and plays an alert sound when target is reached.

## Usage

```
python check_price.py <symbol> <mode> <target> <wav>
```

### Price targets
```
python check_price.py btc above 100000 alert.wav
python check_price.py eth below 3000 alert.wav
```

### Volatility (crypto only)
```
python check_price.py sol vol 10-5 alert.wav   # 10% move in 5 mins
python check_price.py doge vol 5-15 alert.wav  # 5% move in 15 mins
```

### Stocks (needs POLYGON_API_KEY)
```
export POLYGON_API_KEY="your_key"
python check_price.py tsla above 400 alert.wav
```

Get a free key at https://polygon.io

## Requirements
- Python 3 with `requests`
- mpv or mplayer
