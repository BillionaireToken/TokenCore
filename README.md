# TokenCore

This is the github page for Billionaire Token: A super, deflationary gambling oriented, ERC-20 Ethereum token.

Main components:

1. The Coin: Billionaire Token (XBL): A standard ERC-20 token with a burn() function. No minting is allowed.

2. The weekly "Become a Billionaire" decentralized raffle:
---------------------------------------------------------

The Raffle works in the following way: Users must first call approve() on the XBL Contract Address allowing the Raffle to spend tokens on their behalf.
After this, users must call registerTickets() function on the Raffle Contract Address with the number of tickets they want to register.

Example:


  function approve(address _spender, uint256 _amount) returns (bool success) 


So the user will first call approve(RAFFLE_ADDRESS, 20000000000000000000) on the XBL Contract Address. They have just approved the Raffle to spend 20 XBL (+18 zeroes) on their behalf.


  function registerTickets(uint256 number_of_tickets) returns (int8 registerTickets_STATUS)


Assuming the price of one ticket is 20 XBL, then the user must call registerTickets(20) on the Raffle Contract Address.

Now you're in. You've just registered a ticket to the raffle. You have the chance to become the grand winner!

All of this might seem just a tad bit complicated for your average gambler. But not for the cryptohead.

We will be aiming to go mainstream with Billionaire Token and as such we will develop a GUI to be used in conjunction with the Raffle and the Burner .
This GUI will use Metamask and will be usable through our website initially. We will also be looking into developing stand-alone clients.

Basically, people will play the Raffle, play with the Burner, play Poker and not even know they're on a blockchain! 
It will be gambling for the masses with all the benefits that crypto currencies and blockchain technology brings: accountability, traceability and security.


For more information visit https://BillionaireToken.com
