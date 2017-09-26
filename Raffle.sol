/*
The "Become a Billionaire" decentralized Raffle v0.8.6, pre-release.
~by Gluedog
-----------

The weekly Become a Billionaire decentralized raffle will be the basis of the deflationary mechanism for Billionaire Token.
---------------------------------------------------------------------------------------------------------------------------
Every week, users can send 20 XBL to an Ethereum Smart Contract address – this is the equivalent of buying one ticket,
	more tickets mean a better chance to win. Users can buy an unlimited number of tickets to increase their chances.
	At the end of the week, the Smart Contract will choose three winners at random. First place will get 40% of
	the tokens  that were raised during that week, second place gets 20% and third place gets 10%.
	From the remaining 30% of the tokens: 10% are burned – as an offering to the market gods. The other 20% are sent
	to another Smart Contract Address that works like a twisted faucet – rewarding people for burning their own coins.

The Become a Billionaire raffle Smart Contract will run forever, and will have an internal timer that will reset
	itself every seven days. The players are registered to the Raffle by creating an internal mapping,
	inside the Smart Contract, a mapping of every address that registers tokens to it and their associated
	number of tickets. This mapping is reset every time the internal timer resets (every seven days).

+-------------------------------------------------------------------+
| This code is still very much in-development and is likely to be   |
| completely different by the time the first versions are deployed. |
+-------------------------------------------------------------------+



1. Find the winners in the while loop. - CHECK (TEST!)
2. Delete their other entries from the mapping - CHECK (TEST!)
3. Check how much they should win - CHECK (TEST!)
4. Use transfer() function to give them their coins - CHECK (TEST!)
5. Call burnTenPercent() - CHECK (TEST!)
6. Use transfer() to give the remaining (20%) of the coins to the burner_addr - CHECK!

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

contract BillionaireTokenRaffle
{
    address public winner_1;
    address public winner_2;
    address public winner_3;

    address public XBLContract_addr;
    address public burner_addr;
    address public raffle_addr;
    address public owner_addr;

    uint256 public raffle_bowl_counter;
    uint256 public minutes_in_a_week;
    uint256 public next_week;
    uint256 public ticket_price;
    uint256 public total_burned_by_raffle;
    uint256 public current_week;
    uint256 public current_winner_set;
    uint256 public raffle_balance;
    uint256 public total_supply;
    uint256 public rt_upper_limit; /* registerTickets() upper ticket limit */
    uint256 public random_number_counter;
    XBL_ERC20Wrapper private ERC20_CALLS;

    /*   The raffle_bowl is a mapping between an (ever increasing) int and an address.  */
    /*   The raffle_bowl gets reset every week.                                         */
    /*   This needs to be made un-public when the Raffle is deployed for security.      */
    mapping(uint256 => address) public raffle_bowl;
    mapping(uint256 => bytes32) public weekly_burns;
    mapping(address => uint256) public address_to_tickets; /* Make private */
    mapping(address => uint256) public address_to_tickets_prev_week0; /* In resetRaffle() have a mechanism that
                                                                          keeps count of which variable is active.
                                                                      */
    mapping(address => uint256) public address_to_tickets_prev_week1; /* Have a function that returns the real
                                                                         previous week's list to the burner.
                                                                         Only the burner may access this info
                                                                       */
    uint8 public prev_week_ID; /* Keeps track of which variable is the correct indicator of prev week mapping
                                    Can only be [0] or [1].
                                */

	uint256[] public random_numbers; /* Remember the random numbers used inside getNextWinner */

    /* This function will generate a random number between 0 and upper_limit-1  */
    /* Random number generators in Ethereum Smart Contracts are deterministic   */
    function getRand(uint256 upper_limit) public returns (uint256 random_number)
    {
        /* This will have to be replaced with something less predictable.    */
        return uint(block.blockhash(block.number-1)) % upper_limit;
    }

    function BillionaireTokenRaffle()
    {
        /* Billionaire Token contract address */
        XBLContract_addr = 0x49AeC0752E68D0282Db544C677f6BA407BA17ED7;
        ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);

        burner_addr = 0x0; /* Burner address                                      */
        raffle_addr = address(this); /* Own address                              */
        owner_addr = msg.sender; /* Set the owner address as the initial sender */

        ticket_price = 20000000000000000000; /* 20 XBL                                                           */
        total_burned_by_raffle = 0; /* A variable that keeps track of how many tokens were burned by the raffle */
        raffle_balance = 0;
        random_number_counter = 0;

        raffle_bowl_counter = 0; /* This is the key for the raffle_bowl mapping         */
        current_winner_set = 0; /* [0] - No winners are set; [1] - First winner set;   */
                               /* [2] - First two winners set; [3] - All winners set. */
        minutes_in_a_week = 10080;

        next_week = now + minutes_in_a_week * 1 minutes; /* Will get set every time resetRaffle() is called */
        current_week = 0; /* Starts at week 0 */
        prev_week_ID = 0; /* First variable used is address_to_tickets_prev_week0 */

        total_supply = ERC20_CALLS.totalSupply(); /* The whole contract will fail when deployed if this line isn't */
        /* commented out and the Coin with the correct addres doesn't exist */
        rt_upper_limit = total_supply / ticket_price;
    }

    /* A modifier that can be applied to functions to only allow the owner to execute them.       */
    /* This is very useful in cases where one would like to upgrade the deflationary algorithm.   */
    /* We can simple use setter functions on the "Burner address",                                */
    /* so that if we update the Burner, we can just point the Raffle to the new version of it.    */
    modifier onlyOwner()
    {
        require (msg.sender == owner_addr);
        _;
    }

    function setBurnerAddress(address _burner_addr) public onlyOwner
    {
        /* Only the owner can set the burner address. */
        burner_addr = _burner_addr;
    }

    function setTicketPrice(uint256 _ticket_price) public onlyOwner
    {
        /*   Only the owner may or may not be able to change ticket price.  */
        /*   Should the ticket price always be fixed?                       */
        /*   We can always update the Raffle.                               */
        ticket_price = _ticket_price;
    }

    function setOwnerAddr(address _owner_addr) public onlyOwner
    {
        /* The owner can change the owner. */
        /* Because he's the owner          */
        owner_addr = _owner_addr;
    }

    function resetWeeklyVars() public returns (bool success)
    {
        /*
            After the weekly vars have been been reset, the player that last
            registered (if this gets called from registerTickets()) will have
            to have his tickets added to next week's Raffle Bowl.
        */

        total_supply = ERC20_CALLS.totalSupply(); // This has to be called after we have burned the 10%.
        raffle_bowl_counter = 0;
        current_winner_set = 0;
        winner_1 = 0x0;
        winner_2 = 0x0;
        winner_3 = 0x0;
        clearAddressMappings();
        
        prev_week_ID += 1;
        if (prev_week_ID == 3)
        	prev_week_ID == 0;

        random_numbers.length = 0;
        // Check if the addresses were cleared correctly.
        return success;
    }

    function clearAddressMappings() public returns (bool success)
    {
        /*
        This function clears address_to_tickets and raffle_bowl.

          This will also have to clear address_to_tickets, I think the
          only way to actually find the keys is to use the raffle_bowl.

        Check maybe we need to implement a different way to store this data,
          like an array or something, because the mappings may get way too big
          and cost a lot of gas, or have a lot of overhead.
        */
        uint16 counter = 0;
        while (true)
        {
            address_to_tickets[raffle_bowl[counter]] = 0;
            raffle_bowl[counter] = 0x0;

            /* We have to clear the opposite of whatever prev_week_ID is */
            if (prev_week_ID == 0)
            	address_to_tickets_prev_week1[raffle_bowl[counter]] = 0;
            if (prev_week_ID == 1)
            	address_to_tickets_prev_week0[raffle_bowl[counter]] =0;

            if (counter == raffle_bowl_counter)
                return true;

            counter++;
        }
    }

    function clearAddressRaffleBowl(address winner_addr) public returns (bool success)
    {
        /* This function iterates through the raffle bowl mapping
           and removes all the entries with a specific address. */
        for (uint16 i = 0; i <= raffle_bowl_counter; i++)
        {
            if (raffle_bowl[i] == winner_addr)
                raffle_bowl[i] = 0x0;
            // Make sure this doesn't screw up the mapping and leave gaps!
        }
        return success;
    }

    function getPlayerStake(address player) public returns (uint256 stake)
    {
        /* This function takes a player address as argument and returns his stake
        (the full number of tokens he has registered for the raffle during that week) */
        stake = address_to_tickets[player] * ticket_price;
        return stake;
    }

    function getPercent(uint8 percent, uint256 number) public returns (uint256 result)
    {
        return number * percent / 100;
    }

    function resetRaffle() public returns (int8 resetRaffle_STATUS)
    {
        /*
            resetRaffle STATUS CODES:

            [-2] - getNextWinner() error.
            [-1] - We have no participants.
            [0 ] - ALL OK.
            [1 ] - Only one winner, was refunded.
            [2 ] - Two winners were refunded.
        */

        while (now >= next_week)
        {
            next_week = next_week + minutes_in_a_week * 1 minutes;
            current_week += 1;
        }
        if (raffle_bowl_counter == 0)
        {
            /* We have no winners.               */
            /* Reset the rest of the stats here */
            resetWeeklyVars();
            return -1;
        }

        winner_1 = getNextWinner();

        if (winner_1 == 0x0)
        /* Debugging purposes: there is a problem with getNextWinner() */
            return -2;

        else
        {
            current_winner_set += 1;
            winner_2 = getNextWinner();

            if (winner_2 == 0x0)
            {
                /* We have just one winner, refund him the tokens, reset variables */
                raffle_balance = ERC20_CALLS.balanceOf(raffle_addr);
                ERC20_CALLS.transfer(winner_1, raffle_balance);
                resetWeeklyVars();

                return 1;
            }
            else
            {
                current_winner_set += 1;
                winner_3 = getNextWinner();

                if (winner_3 == 0x0)
                {
                    /* We have two winners, refund them the tokens, reset variables */
                    uint256 p1_stake = getPlayerStake(winner_1);
                    ERC20_CALLS.transfer(winner_1, p1_stake);

                    uint256 p2_stake = getPlayerStake(winner_2);
                    ERC20_CALLS.transfer(winner_2, p2_stake);

                    resetWeeklyVars();

                    return 2;
                }
                else
                {
                    /* Three winners, proceed with rewards. */
                    raffle_balance = ERC20_CALLS.balanceOf(raffle_addr);
                    uint256 p1_reward = getPercent(40, raffle_balance);
                    uint256 p2_reward = getPercent(20, raffle_balance);
                    uint256 p3_reward = getPercent(10, raffle_balance);
                    ERC20_CALLS.transfer(winner_1, p1_reward);
                    ERC20_CALLS.transfer(winner_2, p2_reward);
                    ERC20_CALLS.transfer(winner_3, p3_reward);
                    burnTenPercent(raffle_balance);

                    /* Reset variables. */
                    resetWeeklyVars();

                    /* Need some sanity checks here! */
                    return 0;
                }
            }
        }
    }

    function fillWeeklyArrays(uint256 number_of_tickets) private returns (int8 fillWeeklyArrays_STATUS)
    {
    	/*
    		[-1] Error with prev_week_ID
    		[0]  OK
    	*/

    	if ((prev_week_ID != 0) && (prev_week_ID != 1))
        {
        	return -1;
        }

    	address_to_tickets[user_addr] += number_of_tickets;
        
        if (prev_week_ID == 0)
        {
        	address_to_tickets_prev_week0[user_addr] += number_of_tickets;
        }
        else if (prev_week_ID == 1)
        {
        	address_to_tickets_prev_week1[user_addr] += number_of_tickets;
        }

        uint256 _ticket_number = number_of_tickets;
        while (_ticket_number > 0)
        {
            raffle_bowl[raffle_bowl_counter] = user_addr;
            raffle_bowl_counter += 1;
            _ticket_number -= 1;
        }

        return 0;
    }

    function registerTickets(uint256 number_of_tickets) public returns (int8 registerTickets_STATUS)
    {
        /*
            registerTickets RETURN CODES:

			[-4] - fillWeeklyArrays() prev_week_ID value error.
            [-3] - getNextWinner() fail, raised error.
            [-2] - ACTUAL ALLOWANCE CHECK MISMATCH.
            [-1] - INVALID INPUT (zero or too many tickets).
            [0 ] - REGISTERED OK.
        */

        // Check the time:
        if (now >= next_week)
        {
            int8 RAFFLE_STATUS = resetRaffle();
            /*
                resetRaffle() must:

                    1. Give the players their rewards.
                    2. Burn 10%.
                    3. Send coins to the burner.
                    4. Reset all the variables.
                    5. After the variables are re-set, add whatever player registered
                        after time to the new week's raffle_bowl.

            */

            if (RAFFLE_STATUS == -2)
                return -3; /* getNextWinner() errored, raise it!*/
        }
        /* Before users will call registerTickets function,                          */
        /* they will first have to call approve() on the XBL contract address        */
        /* and approve the Raffle to spend tokens on their behalf.                   */
        /* After they have called approve, they will have to call registerTickets()  */

        /* Check for invalid inputs:                       */
        /* Will have to revert() in cases of input errors */
        if (number_of_tickets == 0)
            return -1;

        if (number_of_tickets >= rt_upper_limit)
            return -1;

        address user_addr = msg.sender;

        uint256 user_submitted_allowance = ticket_price * number_of_tickets;
        uint256 actual_allowance = ERC20_CALLS.allowance(user_addr, raffle_addr);

        if (actual_allowance < user_submitted_allowance)
            return -2;

        /*  Reaching this point means the ticket registrant is legit  */
        /*  Every ticket will add an entry to the raffle_bowl         */

        if (fillWeeklyArrays(number_of_tickets) == -1)
        	return -4;
        else
        	return 0;
    }

    function burnTenPercent(uint256 raffle_balance) public returns (bool success_state)
    {
        uint256 amount_to_burn = getPercent(10, raffle_balance);
        total_burned_by_raffle += amount_to_burn;

        bool burn_success = ERC20_CALLS.burn(amount_to_burn);

        if (burn_success == true)
            return true;
        else
            return false;

        /* Test here to see if we need more checks. */
    }

    function getNextWinner() public returns (address next_winner)
    {
        /*
        Function that returns the next winner.
            It will generate a random number between raffle_bowl start value and raffle_bowl end value
            (and will remember this number so that it's not chosen again)
            Every time a winner is found they are discarded from the array, and the loop continues.
        */
        if (current_winner_set == 3)
            return 0x0;

        uint256 _rand = getRand(raffle_bowl_counter+1);
        random_numbers[random_number_counter] = _rand;
        random_number_counter += 1;

        if (current_winner_set == 0)
        {
            address _winner_1 = raffle_bowl[_rand];
            clearAddressRaffleBowl(_winner_1);
            return _winner_1;
        }

        if (current_winner_set == 1)
        {
            address _winner_2 = raffle_bowl[_rand];
            if ((_winner_2 == 0x0) || (_winner_2 == _winner_1))
                return 0x0; // Huge error!
            else
            {
                clearAddressRaffleBowl(_winner_2);
                return _winner_2;
            }
        }

        if (current_winner_set == 2)
        {
            address _winner_3 = raffle_bowl[_rand];
            if ((_winner_3 == 0x0) || (_winner_3 == _winner_2) || (_winner_3 == _winner_1))
                return 0x0; // Huge error!
            else
            {
                clearAddressRaffleBowl(_winner_3);
                return _winner_3;
            }
        }
    }

    /* <<<--- Debug ONLY functions. These will be removed from the final version --->>> */
    /* <<<--- Debug ONLY functions. These will be removed from the final version --->>> */
    /* <<<--- Debug ONLY functions. These will be removed from the final version --->>> */

    function setXBLAddr(address _XBLContract_addr) public onlyOwner
    {
        /* Debugging purposes. This will be hardcoded in the original version. */
        XBLContract_addr = _XBLContract_addr;
        ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
    }

    function testCallTotalSupply() public returns (uint256 total_supply)
    {
        return ERC20_CALLS.totalSupply();
    }

    function demoPopulateVariables0_OneRegistrant() public
    {
        /* Populate the variables as if raffle just had one registrant - normally it should return his balance. */
        raffle_bowl[0] = msg.sender;
        raffle_bowl_counter += 1;

        address_to_tickets[msg.sender] = 1;
    }

    function demoPopulateVariables1_TwoRegistrants(address extra_winner_0) public
    {
        /* Populate the variables as if raffle just had two registrant - normally it should return their balance. */
        raffle_bowl[0] = msg.sender;
        raffle_bowl[1] = extra_winner_0;
        raffle_bowl_counter += 2;

        address_to_tickets[msg.sender] = 1;
        address_to_tickets[extra_winner_0] = 1;
    }

    function demoPopulateVariables2_ThreeWinners(address extra_winner_0, address extra_winner_1) public
    {
        /* Populate the variables as if raffle had been going on for a while and we have a
            bunch of entries in the raffle_bowl.
        */
        raffle_bowl[0] = msg.sender;
        raffle_bowl[1] = extra_winner_0;
        raffle_bowl[2] = extra_winner_1;
        raffle_bowl_counter += 3;

        address_to_tickets[msg.sender] = 1;
        address_to_tickets[extra_winner_0] = 1;
        address_to_tickets[extra_winner_1] = 1;
    }

    function testPopulateAndClearAddressMappings() public
    {
        /* First populate address_to_tickets and raffle_bowl, then call clearAddressMappings to
            test if they get properly reset
        */
    }
}
