/* The Burner v0.1 
*  ~by gluedog
*
* The Burner is Billionaire Token's version of a "Faucet" - an evil, twisted Faucet. 
* Just like a Faucet, people can use it to get some extra coins. 
* Unlike a Faucet, the Burner will also burn coins and reduce the maximum supply in the process of giving people extra coins.
*
* The Burner must:
*
*
* 1. Receive XBL Tokens from the Raffle
* 2. Have a registerBurn() function.
* 3. The registerBurn() function:
*     - Checks allowance from users.
* 	  - Checks own supply. If own_supply <= user_submitted_tokens+extra_bonus it will use revert() to revert the Transaction.
* 	  - Calls burnFrom() to burn the users tokens.
* 	  - Sends the user their burned tokens +extra_bonus.
*/

pragma solidity ^0.4.0;

contract XBL_ERC20Wrapper
{
	function transferFrom(address from, address to, uint value) returns (bool success);
	function transfer(address _to, uint _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);
	function burn(uint256 _value) returns (bool success);
	function balanceOf(address _owner) constant returns (uint256 balance);
	function totalSupply() constant returns (uint256 total_supply);
}

contract TheBurner
{
	XBL_ERC20Wrapper ERC20_CALLS;
	uint8 public extra_bonus; /* The percentage of extra coins that the burner will reward people for. */
	address burner_addr;
	address raffle_addr;

	modifier onlyOwner() 
    {
    	require (msg.sender == owner_addr);
    	_;
  	}

  	function setRaffleAddress(address _raffle_addr) onlyOwner
  	{
  		/* Allows the owner to set the raffle address */
  		raffle_addr = _raffle_addr;
  	}

	function TheBurner()
	{
		XBLContract_addr = 0x49AeC0752E68D0282Db544C677f6BA407BA17ED7;
		ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
		extra_bonus = 5; /* 5% reward for burning your own coins, provided the burner has enough. */
		burner_addr = address(this);
	}

	function registerBurn(uint256 tokens_registered) returns (int8 registerBurn_STATUS)
	{
		address user = msg.sender;
		uint256 own_supply = ERC20_CALLS.balanceOf(user_addr, raffle_addr);
	}
}
