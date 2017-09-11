# Simple python script used to calculate the amount of XBL associated with a purchase in BTC, ETH and LTC
# v.02

import urllib, json

current_bonus = "50"

BTC_url = "https://api.coinmarketcap.com/v1/ticker/bitcoin/"
LTC_url = "https://api.coinmarketcap.com/v1/ticker/litecoin/"
ETH_url = "https://api.coinmarketcap.com/v1/ticker/ethereum/"

btc_response = urllib.urlopen(BTC_url)
btc_data = json.loads(btc_response.read())
btc_price = float(btc_data[0]["price_usd"])

eth_response = urllib.urlopen(ETH_url)
eth_data = json.loads(eth_response.read())
eth_price = float(eth_data[0]["price_usd"])

ltc_response = urllib.urlopen(LTC_url)
ltc_data = json.loads(ltc_response.read())
ltc_price = float(ltc_data[0]["price_usd"])

while True:
    choice = raw_input("1). LTC\n2). BTC\n3). ETH\n>> ")

    if choice == "1":
        amount_ltc = float(raw_input("Amount of LTC sent: "))
        base_xbl = amount_ltc * ltc_price / 0.1
        
        print "Base XBL for ["+str(amount_ltc)+"] LTC is ["+str(base_xbl)+"] tokens for a price of $"+str(ltc_price)+"/LTC."
        total_xbl = float(base_xbl) + float((base_xbl * (float(current_bonus)/100)))
        print "Total XBL for ["+str(amount_ltc)+"] LTC is ["+str(total_xbl)+"] tokens with "+current_bonus+"% bonus"

    if choice == "2":
        amount_btc = float(raw_input("Amount of BTC sent: "))
        base_xbl = amount_btc * btc_price / 0.1

        print "Base XBL for ["+str(amount_btc)+"] BTC is ["+str(base_xbl)+"] tokens for a price of $"+str(btc_price)+"/BTC."
        total_xbl = float(base_xbl) + float((base_xbl * (float(current_bonus)/100)))
        print "Total XBL for ["+str(amount_btc)+"] BTC is ["+str(total_xbl)+"] tokens with "+current_bonus+"% bonus"

    if choice == "3":
        amount_eth = float(raw_input("Amount of ETH sent: "))
        base_xbl = amount_eth * eth_price / 0.1

        print "Base XBL for ["+str(amount_eth)+"] ETH is ["+str(base_xbl)+"] tokens for a price of $"+str(eth_price)+"/ETH."
        total_xbl = float(base_xbl) + float((base_xbl * (float(current_bonus)/100)))
        print "Total XBL for ["+str(amount_eth)+"] ETH is ["+str(total_xbl)+"] tokens with "+current_bonus+"% bonus"
