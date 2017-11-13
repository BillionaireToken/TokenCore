# TokenCore

### This is the github page for Billionaire Token: A super, deflationary gambling oriented, ERC-20 Ethereum token.

## Main components:

### 1. The Coin: Billionaire Token (XBL): 

A standard ERC-20 token with a burn() function. No minting is allowed.


### 2. The weekly "Become a Billionaire" decentralized raffle:

The Raffle works in the following way: Users must first call approve() on the XBL Contract Address allowing the Raffle to spend tokens on their behalf.
After this, users must call registerTickets() function on the Raffle Contract Address with the number of tickets they want to register.

Example:


  **function approve(address _spender, uint256 _amount) returns (bool success)**


The user will first call approve(RAFFLE_ADDRESS, 10000000000000000000) on the XBL Contract Address. They have just approved the Raffle to spend 10 XBL (+18 zeroes) on their behalf.


  **function registerTickets(uint256 number_of_tickets) returns (int8 registerTickets_STATUS)**


Assuming the price of one ticket is 10 XBL, then the user must call registerTickets(1) on the Raffle Contract Address. After that, they've just registered a ticket to the raffle. They have the chance to become the grand winner!

### ------ 

All of this is easy for a cryptohead but might seem just a tad bit complicated for your average gambler.

We want to go mainstream with Billionaire Token and as such we have developed and are maintaining and updating web-based graphical user interface to be used in conjunction with the Raffle and the Burner .
This GUI makes use of Metamask and web3 and is be usable through our website. We will also be looking into developing stand-alone clients.

People will play the Raffle, play with the Burner, play Poker and not even know they're on a blockchain! 
It will be gambling for the masses with all the benefits that crypto currencies and blockchain technology brings: accountability, traceability and security.


For more information visit https://BillionaireToken.com
