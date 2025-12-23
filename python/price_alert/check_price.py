import shutil
import subprocess
import time
import requests
import sys
import os
from collections import deque

CRYPTO = {
    'BTC': 'bitcoin', 'BITCOIN': 'bitcoin',
    'ETH': 'ethereum', 'ETHEREUM': 'ethereum',
    'SOL': 'solana', 'SOLANA': 'solana',
    'DOGE': 'dogecoin', 'DOGECOIN': 'dogecoin',
    'ADA': 'cardano', 'CARDANO': 'cardano',
    'XRP': 'ripple', 'RIPPLE': 'ripple',
    'XMR': 'monero', 'MONERO': 'monero',
    'LTC': 'litecoin', 'LITECOIN': 'litecoin',
}
POLL_INTERVAL = 30

def get_crypto_price(cg_id, session):
    try:
        response = session.get("https://api.coingecko.com/api/v3/simple/price",
                               params={'ids': cg_id, 'vs_currencies': 'usd'}, timeout=10)
        response.raise_for_status()
        return response.json()[cg_id]['usd']
    except (requests.RequestException, KeyError, ValueError) as e:
        print(f"Fetch failed ({type(e).__name__}: {e})")
        return None

def get_stock_price(symbol, api_key, session):
    try:
        response = session.get(f"https://api.polygon.io/v2/last/trade/{symbol.upper()}",
                               params={'apiKey': api_key}, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data.get('status') != 'success':
            print(f"Fetch failed (API status: {data.get('status', 'unknown')})")
            return None
        return data['last']['price']
    except (requests.RequestException, KeyError, ValueError) as e:
        print(f"Fetch failed ({type(e).__name__}: {e})")
        return None

def crossed_threshold(price, last_price, target, check_above):
    """Return True if price just crossed the target threshold."""
    if last_price is None:
        return price >= target if check_above else price <= target
    if check_above:
        return price >= target and last_price < target
    return price <= target and last_price > target

def get_audio_player():
    """Return available audio player command, or None if not found."""
    if shutil.which("mpv"):
        return ["mpv", "--loop=inf", "--really-quiet"]
    if shutil.which("mplayer"):
        return ["mplayer", "-loop", "0", "-nolirc", "-quiet"]
    return None

def play_alert(wav, player_cmd):
    subprocess.Popen(player_cmd + [wav],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def update_deques(now, price, price_history, min_prices, max_prices, cutoff):
    """Update price history and min/max deques, prune old entries."""
    price_history.append((now, price))

    while min_prices and min_prices[-1][1] > price:
        min_prices.pop()
    min_prices.append((now, price))

    while max_prices and max_prices[-1][1] < price:
        max_prices.pop()
    max_prices.append((now, price))

    while price_history and price_history[0][0] < cutoff:
        old_time, _ = price_history.popleft()
        if min_prices and min_prices[0][0] == old_time:
            min_prices.popleft()
        if max_prices and max_prices[0][0] == old_time:
            max_prices.popleft()

def check_volatility(price_history, min_prices, max_prices, time_mins, target_pct):
    """Check if volatility threshold is met. Returns (triggered, swing_pct) or (False, None)."""
    if not price_history:
        return False, None

    now = price_history[-1][0]
    span_mins = (now - price_history[0][0]) / 60.0

    if span_mins < time_mins:
        return False, None

    min_price = min_prices[0][1]
    max_price = max_prices[0][1]

    if min_price <= 0:
        return False, None

    swing_pct = (max_price - min_price) / min_price * 100
    return swing_pct >= target_pct, swing_pct

def run_volatility_monitor(symbol, target_pct, time_mins, wav, player_cmd, fetch_price):
    """Run the volatility monitoring loop."""
    price_history, min_prices, max_prices = deque(), deque(), deque()
    triggered = False

    while True:
        price = fetch_price()
        now = time.monotonic()
        time_str = time.strftime('%H:%M:%S')

        if price is not None and price > 0:
            cutoff = now - (time_mins * 60)
            update_deques(now, price, price_history, min_prices, max_prices, cutoff)
            span_mins = (now - price_history[0][0]) / 60.0

            if triggered:
                print(f"{symbol}: ${price:,.2f} ({time_str})")
            elif span_mins < time_mins:
                print(f"{symbol}: ${price:,.2f} (warming up...) ({time_str})")
            else:
                alert, swing_pct = check_volatility(
                    price_history, min_prices, max_prices, time_mins, target_pct)
                if alert:
                    min_price, max_price = min_prices[0][1], max_prices[0][1]
                    print(f"\n!!! {symbol} VOLATILITY: {swing_pct:.2f}% range in {span_mins:.1f}min "
                          f"(low ${min_price:,.2f}, high ${max_price:,.2f}) !!!")
                    print(f"   Starting endless alert sound... (stop with: killall {player_cmd[0]})\n")
                    play_alert(wav, player_cmd)
                    triggered = True
                else:
                    print(f"{symbol}: ${price:,.2f} (range {swing_pct:.2f}% / {time_mins}min) ({time_str})")

        time.sleep(POLL_INTERVAL)

def run_price_monitor(symbol, mode, target, wav, player_cmd, fetch_price):
    """Run the price threshold monitoring loop."""
    triggered = False
    last_price = None

    while True:
        price = fetch_price()
        time_str = time.strftime('%H:%M:%S')

        if price is not None:
            print(f"{symbol}: ${price:,.2f} ({time_str})")
            if not triggered and crossed_threshold(price, last_price, target, mode == 'above'):
                if mode == 'above':
                    print(f"\n!!! {symbol} BROKE ABOVE ${target:,}! Price: ${price:,.2f} !!!")
                else:
                    print(f"\n!!! {symbol} DROPPED BELOW ${target:,}! Price: ${price:,.2f} !!!")
                print(f"   Starting endless alert sound... (stop with: killall {player_cmd[0]})\n")
                play_alert(wav, player_cmd)
                triggered = True
            last_price = price

        time.sleep(POLL_INTERVAL)

def parse_args():
    if len(sys.argv) != 5:
        print("Usage: check_price.py <symbol> <mode> <target> <wav>")
        print("")
        print("Modes:")
        print("  above <price>       Alert when price rises to target")
        print("  below <price>       Alert when price drops to target")
        print("  vol <pct>-<mins>    Alert on volatility (crypto only)")
        print("")
        print("Examples:")
        print("  btc above 100000 alert.wav")
        print("  eth below 3000 alert.wav")
        print("  sol vol 10-5 alert.wav      (10% move in 5 mins)")
        print("  tsla above 400 alert.wav    (needs POLYGON_API_KEY)")
        sys.exit(1)

    symbol, mode, target_str, wav = sys.argv[1], sys.argv[2].lower(), sys.argv[3], sys.argv[4]

    if not os.path.isfile(wav):
        sys.exit(f"WAV not found: {wav}")

    if mode == 'vol':
        if '-' not in target_str:
            sys.exit("Volatility format: <percent>-<minutes> (e.g., 10-5)")
        try:
            pct_str, mins_str = target_str.split('-', 1)
            target_pct, time_mins = float(pct_str), int(mins_str)
        except ValueError:
            sys.exit("Invalid vol format: must be number-number")
        if target_pct <= 0 or time_mins <= 0:
            sys.exit("Percent and minutes must be > 0")
        return symbol, mode, (target_pct, time_mins), wav

    if mode not in ('above', 'below'):
        sys.exit("Mode must be 'above', 'below', or 'vol'")
    try:
        target = float(target_str)
    except ValueError:
        sys.exit("Target price must be a number.")
    return symbol, mode, target, wav

def main():
    player_cmd = get_audio_player()
    if not player_cmd:
        sys.exit("Error: mpv or mplayer not found in PATH")

    symbol, mode, target, wav = parse_args()
    symbol_upper = symbol.upper()
    cg_id = CRYPTO.get(symbol_upper)

    if not cg_id:
        api_key = os.getenv('POLYGON_API_KEY')
        if not api_key:
            sys.exit("Error: POLYGON_API_KEY not set")

    with requests.Session() as session:
        if cg_id:
            fetch_price = lambda: get_crypto_price(cg_id, session)
        else:
            fetch_price = lambda: get_stock_price(symbol, api_key, session)

        print(f"Monitoring {symbol_upper}...")
        if mode == 'vol':
            target_pct, time_mins = target
            print(f"Alert on ±{target_pct:.1f}% change within {time_mins} minutes")
        else:
            direction_word = "above or at" if mode == 'above' else "below or at"
            print(f"Alert when price goes {direction_word} ${target:,}")
        print("Press Ctrl+C to stop monitoring.\n")

        try:
            if mode == 'vol':
                target_pct, time_mins = target
                run_volatility_monitor(symbol_upper, target_pct, time_mins, wav, player_cmd, fetch_price)
            else:
                run_price_monitor(symbol_upper, mode, target, wav, player_cmd, fetch_price)
        except KeyboardInterrupt:
            print("\nStopped.")

if __name__ == "__main__":
    main()
