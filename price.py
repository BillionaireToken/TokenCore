# Simple python script used to calculate the amount of XBL associated with a purchase in BTC, ETH and LTC\
# v.01 by Gluedog
# Next version will use the coinmarketcap API to grab prices automatically so we won't have to hardcode them.

btc_price = 4572.78
eth_price = 389.07  
ltc_price = 61.06
current_bonus = "70"


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
