import subprocess
import time
import requests
import sys
import os


def get_bitcoin_price_usd():
    url = "https://api.coingecko.com/api/v3/simple/price"
    params = {'ids': 'bitcoin', 'vs_currencies': 'usd'}
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        return response.json()['bitcoin']['usd']
    except Exception as e:
        print(f"Error fetching price: {e}")
        return None


def main():
    if len(sys.argv) != 4:
        print("Usage: python coin_price.py <above|below> "
              "<target_price> <path_to_wav_file>")
        print("Examples:")
        print("  Moon alert: python coin_price.py above "
              "100000 alert.wav")
        print("  Dip alert:  python coin_price.py below "
              "80000 dip.wav")
        sys.exit(1)

    direction = sys.argv[1].lower()
    if direction not in ["above", "below"]:
        print("First argument must be 'above' or 'below'")
        sys.exit(1)

    try:
        target_price = float(sys.argv[2])
    except ValueError:
        print("Target price must be a number.")
        sys.exit(1)

    wav_file = sys.argv[3]

    if not os.path.isfile(wav_file):
        print(f"WAV file not found: {wav_file}")
        sys.exit(1)

    direction_word = "above or at" if direction == "above" else "below or at"
    print("Monitoring Bitcoin price...")
    print(f"Alert when price goes {direction_word} ${target_price:,}")
    print("Press Ctrl+C to stop monitoring.\n")

    triggered = False
    last_price = None

    try:
        while True:
            price = get_bitcoin_price_usd()
            if price is not None:
                print(f"Current BTC price: ${price:,.2f} "
                      f"(checked at {time.strftime('%H:%M:%S')})")

                if not triggered:
                    if (direction == "above" and
                        price >= target_price and
                        (last_price is None or
                         last_price < target_price)):
                        print(f"\n!!! BITCOIN BROKE ABOVE "
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
                        print(f"\n!!! BITCOIN DROPPED BELOW "
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
                print("Failed to fetch price, retrying...")

            time.sleep(45)

    except KeyboardInterrupt:
        print("\nMonitoring stopped.")


if __name__ == "__main__":
    main()
