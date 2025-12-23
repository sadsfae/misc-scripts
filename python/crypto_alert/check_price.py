import subprocess
import time
import requests
import sys
import os


def get_price(symbol_input):
    symbol_lower = symbol_input.lower()
    if symbol_lower in ['btc', 'bitcoin']:
        cg_id = 'bitcoin'
    elif symbol_lower in ['eth', 'ethereum']:
        cg_id = 'ethereum'
    else:
        cg_id = None

    if cg_id:
        url = "https://api.coingecko.com/api/v3/simple/price"
        params = {'ids': cg_id, 'vs_currencies': 'usd'}
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            return response.json()[cg_id]['usd']
        except Exception:
            return None

    else:
        api_key = os.getenv('POLYGON_API_KEY')
        if not api_key:
            print("Error: POLYGON_API_KEY environment variable not set")
            return None

        url = f"https://api.polygon.io/v2/last/trade/{symbol_input.upper()}"
        params = {'apiKey': api_key}
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            if data.get('status') == 'success':
                return data['last']['price']
        except Exception:
            return None
        return None


def main():
    if len(sys.argv) != 5:
        print("Usage: python check_price.py <symbol> <above|below> "
              "<target_price> <path_to_wav_file>")
        print("Examples:")
        print("  Crypto: python check_price.py btc above 100000 alert.wav")
        print("  Crypto: python check_price.py eth below 3000 dip.wav")
        print("  Stock:  python check_price.py tsla above 400 alert.wav")
        print("  Stock:  python check_price.py ibm below 150 dip.wav")
        print("")
        print("For stocks, set POLYGON_API_KEY environment variable")
        sys.exit(1)

    symbol_input = sys.argv[1]
    symbol = symbol_input.upper()
    direction = sys.argv[2].lower()
    if direction not in ["above", "below"]:
        print("Second argument must be 'above' or 'below'")
        sys.exit(1)

    try:
        target_price = float(sys.argv[3])
    except ValueError:
        print("Target price must be a number.")
        sys.exit(1)

    wav_file = sys.argv[4]

    if not os.path.isfile(wav_file):
        print(f"WAV file not found: {wav_file}")
        sys.exit(1)

    direction_word = "above or at" if direction == "above" else "below or at"
    print(f"Monitoring {symbol} price...")
    print(f"Alert when price goes {direction_word} ${target_price:,}")
    print("Press Ctrl+C to stop monitoring.\n")

    triggered = False
    last_price = None

    try:
        while True:
            price = get_price(symbol_input)
            if price is not None:
                print(f"Current {symbol} price: ${price:,.2f} "
                      f"(checked at {time.strftime('%H:%M:%S')})")

                if not triggered:
                    if (direction == "above" and
                        price >= target_price and
                        (last_price is None or
                         last_price < target_price)):
                        print(f"\n!!! {symbol} BROKE ABOVE "
                              f"${target_price:,}! "
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

                    elif (direction == "below" and
                          price <= target_price and
                          (last_price is None or
                           last_price > target_price)):
                        print(f"\n!!! {symbol} DROPPED BELOW "
                              f"${target_price:,}! "
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

                last_price = price
            else:
                print("Failed to fetch price, retrying in 30s...")

            time.sleep(30)

    except KeyboardInterrupt:
        print("\nMonitoring stopped.")


if __name__ == "__main__":
    main()
