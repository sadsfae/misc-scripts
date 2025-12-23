import subprocess
import time
import requests
import sys
import os
from collections import deque

TICKER_TO_ID = {
    'btc': 'bitcoin',
    'eth': 'ethereum',
    'sol': 'solana',
    'doge': 'dogecoin',
    'ada': 'cardano',
    'xrp': 'ripple',
    'zec': 'zcash',
    'xmr': 'monero',
    'bnb': 'binancecoin',
    'dot': 'polkadot',
    'avax': 'avalanche-2',
    'link': 'chainlink',
    'matic': 'polygon',
    'shib': 'shiba-inu',
    'ltc': 'litecoin',
    'bch': 'bitcoin-cash',
    'uni': 'uniswap',
}

def get_price(coin_id):
    url = "https://api.coingecko.com/api/v3/simple/price"
    params = {'ids': coin_id, 'vs_currencies': 'usd'}
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        if coin_id in data and 'usd' in data[coin_id]:
            return data[coin_id]['usd']
        else:
            print(f"Invalid CoinGecko ID: '{coin_id}'")
            print("Try common tickers: btc, eth, sol, doge, ada, etc.")
            return None
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 429:
            print("Rate limited by CoinGecko")
        else:
            print(f"HTTP error: {e}")
        return None
    except Exception as e:
        print(f"Request failed: {e}")
        return None

def main():
    if len(sys.argv) != 5:
        print("Usage: python coin_price.py <ticker> <mode> <target> "
              "<wav_file>")
        print("")
        print("Modes:")
        print("  Price level: above <price>   or   below <price>")
        print("  Volatility:  vol <percent>-<minutes>")
        print("")
        print("Examples:")
        print("  python coin_price.py btc above 100000 moon.wav")
        print("  python coin_price.py eth below 4000 dip.wav")
        print("  python coin_price.py sol vol 8-15 vol_alert.wav")
        print("  python coin_price.py doge vol 10-5 pump.wav")
        print("")
        print("Supported tickers: btc, eth, sol, doge, ada, xrp, bnb,")
        print("  dot, avax, link, matic, shib, etc.")
        print("Add more in TICKER_TO_ID dict if needed.")
        sys.exit(1)

    ticker_input = sys.argv[1].lower()
    mode_input = sys.argv[2].lower()
    target_str = sys.argv[3]
    wav_file = sys.argv[4]

    if not os.path.isfile(wav_file):
        print(f"WAV file not found: {wav_file}")
        sys.exit(1)

    if ticker_input not in TICKER_TO_ID:
        print(f"Unsupported ticker: '{ticker_input}'")
        print("Common: btc, eth, sol, doge, ada, xrp, bnb, etc.")
        sys.exit(1)

    coin_id = TICKER_TO_ID[ticker_input]
    coin_name = ticker_input.upper()

    if mode_input in ["above", "below"]:
        mode = mode_input
        try:
            target_price = float(target_str)
        except ValueError:
            print("For above/below, target must be a price number.")
            sys.exit(1)

        direction_word = "above or at" if mode == "above" else "below or at"
        print(f"Monitoring {coin_name} price...")
        print(f"Alert when price goes {direction_word} "
              f"${target_price:,.0f}")

    elif mode_input == "vol":
        if '-' not in target_str:
            print("For vol mode, use format: percent-minutes (e.g., 5-10)")
            sys.exit(1)
        try:
            percent_str, minutes_str = target_str.split('-', 1)
            target_percent = float(percent_str)
            time_minutes = int(minutes_str)
        except ValueError:
            print("Invalid vol format: must be number-number")
            sys.exit(1)

        if target_percent <= 0 or time_minutes <= 0:
            print("Percent and minutes must be > 0")
            sys.exit(1)

        mode = "vol"
        print(f"Monitoring {coin_name} volatility...")
        print(f"Alert when price changes by ±{target_percent:.1f}% "
              f"within {time_minutes} minutes")

    else:
        print("Mode must be 'above', 'below', or 'vol'")
        sys.exit(1)

    print("Press Ctrl+C to stop monitoring.\n")

    triggered = False
    price_history = deque()
    check_interval = 60

    try:
        while True:
            price = get_price(coin_id)
            current_time = time.time()

            if price is not None:
                price_history.append((current_time, price))

                if mode == "vol":
                    cutoff = current_time - (time_minutes * 60)
                else:
                    cutoff = current_time - (5 * 60)

                while price_history and price_history[0][0] < cutoff:
                    price_history.popleft()

                if mode == "vol" and len(price_history) >= 2 and not triggered:
                    oldest_time, oldest_price = price_history[0]
                    time_span_min = (current_time - oldest_time) / 60.0

                    if time_span_min >= time_minutes - 0.5:
                        change_percent = (price - oldest_price) / oldest_price * 100
                        abs_change = abs(change_percent)

                        if abs_change >= target_percent:
                            direction_sign = "↑" if change_percent > 0 else "↓"
                            print(f"\n!!! {coin_name} VOLATILITY ALERT: "
                                  f"{direction_sign} {abs_change:.2f}% "
                                  f"in {time_span_min:.1f} minutes !!!\n")
                            print("   Starting endless alert sound... "
                                  "(stop with: killall mplayer)\n")
                            triggered = True
                            subprocess.Popen(
                                ["mplayer", "-loop", "0", "-nolirc", "-quiet",
                                 wav_file],
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL
                            )
                        else:
                            print(f"{time_minutes}-min change: "
                                  f"{change_percent:+.2f}%   "
                                  f"({time.strftime('%H:%M:%S')})")
                    else:
                        print(f"Current {coin_name} price: ${price:,.2f}   "
                              f"({time.strftime('%H:%M:%S')})")
                else:
                    print(f"Current {coin_name} price: ${price:,.2f}   "
                          f"({time.strftime('%H:%M:%S')})")

                if mode != "vol" and not triggered:
                    last_price = None if len(price_history) < 2 else price_history[-2][1]

                    if (mode == "above" and price >= target_price and
                        (last_price is None or last_price < target_price)):
                        print(f"\n!!! {coin_name} BROKE ABOVE "
                              f"${target_price:,.0f}! "
                              f"Price: ${price:,.2f} !!!")
                        print("   Starting endless alert sound... "
                              "(stop with: killall mplayer)\n")
                        triggered = True
                        subprocess.Popen(
                            ["mplayer", "-loop", "0", "-nolirc", "-quiet",
                             wav_file],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL
                        )

                    elif (mode == "below" and price <= target_price and
                          (last_price is None or last_price > target_price)):
                        print(f"\n!!! {coin_name} DROPPED BELOW "
                              f"${target_price:,.0f}! "
                              f"Price: ${price:,.2f} !!!")
                        print("   Starting endless alert sound... "
                              "(stop with: killall mplayer)\n")
                        triggered = True
                        subprocess.Popen(
                            ["mplayer", "-loop", "0", "-nolirc", "-quiet",
                             wav_file],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL
                        )

            time.sleep(check_interval)

    except KeyboardInterrupt:
        print("\nMonitoring stopped.")


if __name__ == "__main__":
    main()
