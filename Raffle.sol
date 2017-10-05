/*
The "Become a Billionaire" decentralized Raffle v0.9, pre-release.
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
*/

pragma solidity ^0.4.8;
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
    bool private DEBUG = true;

    /* Most of these variables must be made private before deploying the final version */

    address public winner_1;
    address public winner_2;
    address public winner_3;

    address public XBLContract_addr;
    address public burner_addr;
    address public raffle_addr;
    address public owner_addr;

    uint64 public unique_players; /* Unique number of addresses registered in a week */
    uint128 public raffle_bowl_counter;
    uint256[] public seeds;
    uint256 private minutes_in_a_week;
    uint256 public next_week_timestamp;
    uint256 public ticket_price;
    uint256 public total_burned_by_raffle;
    uint256 public current_week;
    uint256 public current_winner_set;
    uint256 public raffle_balance;
    uint256 public total_supply;

    XBL_ERC20Wrapper private ERC20_CALLS;

    /*   The raffle_bowl is a mapping between an (ever increasing) int and an address.  */
    /*   The raffle_bowl gets reset every week.                                         */
    /*   This needs to be made un-public when the Raffle is deployed for security.      */
    mapping(uint256 => address) public raffle_bowl;
    //mapping(uint256 => bytes32) public weekly_burns;
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

    function getRand(uint256 upper_limit) public returns (uint256 random_number)
    {
        return uint(sha256(uint256(block.blockhash(block.number-1)) * uint256(sha256(msg.sender)))) % upper_limit;
    }
    
    function getRandWithSeed(uint256 upper_limit, uint seed) public returns (uint256 random_number)
    {
        return seed % upper_limit;
    }

    function getLastWeekStake(address user_addr) public onlyBurner returns (uint256 last_week_stake)
    {
        /* The burner accesses this function to retrieve each player's stake from the previous week. */
        if (prev_week_ID == 0)
            return address_to_tickets_prev_week0[user_addr];
        if (prev_week_ID == 1)
            return address_to_tickets_prev_week1[user_addr];
    }

    function BillionaireTokenRaffle()
    {
        /* Billionaire Token contract address */
        XBLContract_addr = 0x49AeC0752E68D0282Db544C677f6BA407BA17ED7;

        if (DEBUG == false)
        {
            ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
            total_supply = ERC20_CALLS.totalSupply();
            ticket_price = 10000000000000000000; /* 10 XBL  */
        }
        else if (DEBUG == true)
        {
            ticket_price = 10; /* Easier to test */
        }

        burner_addr = 0x0; /* Burner address                                      */
        raffle_addr = address(this); /* Own address                              */
        owner_addr = msg.sender; /* Set the owner address as the initial sender */

        total_burned_by_raffle = 0; /* A variable that keeps track of how many tokens were burned by the raffle */
        raffle_balance = 0;
        unique_players = 0;

        raffle_bowl_counter = 0; /* This is the key for the raffle_bowl mapping         */
        current_winner_set = 0; /* [0] - No winners are set; [1] - First winner set;   */
                               /* [2] - First two winners set; [3] - All winners set. */
        minutes_in_a_week = 10080;

        next_week_timestamp = now + minutes_in_a_week * 1 minutes; /* Will get set every time resetRaffle() is called */
        current_week = 0; /* Starts at week 0 */
        prev_week_ID = 0; /* First variable used is address_to_tickets_prev_week0 */
    }

    /* A modifier that can be applied to functions to only allow the owner to execute them.       */
    /* This is very useful in cases where one would like to upgrade the deflationary algorithm.   */
    /* We can simply use setter functions on the "Burner address",                                */
    /* so that if we update the Burner, we can just point the Raffle to the new version of it.    */
    modifier onlyOwner()
    {
        require (msg.sender == owner_addr);
        _;
    }

    modifier onlyBurner()
    {
        require(msg.sender == burner_addr);
        _;
    }

    function setBurnerAddress(address _burner_addr) public onlyOwner
    {
        burner_addr = _burner_addr;
    }

    function setTicketPrice(uint256 _ticket_price) public onlyOwner
    {
        ticket_price = _ticket_price;
    }

    function setOwnerAddr(address _owner_addr) public onlyOwner
    {
        owner_addr = _owner_addr;
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

    function resetWeeklyVars() public returns (bool success)
    {
        /*  After the weekly vars have been been reset, the player that last
            registered (if this gets called from registerTickets()) will have
            to have his tickets added to next week's Raffle Bowl.               */

        total_supply = ERC20_CALLS.totalSupply();

        raffle_bowl_counter = 0;
        current_winner_set = 0;
        unique_players = 0;
        winner_1 = 0x0;
        winner_2 = 0x0;
        winner_3 = 0x0;
        clearAddressMappings();
        
        prev_week_ID++;
        if (prev_week_ID > 2)
            prev_week_ID = 0;

        /* Should also test if everything was cleared correctly. */
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
        uint32 counter = 0;
        while (true)
        {
            address_to_tickets[raffle_bowl[counter]] = 0;
            raffle_bowl[counter] = 0x0;

            /* We have to clear the opposite of whatever prev_week_ID is */
            if (prev_week_ID == 0)
                address_to_tickets_prev_week1[raffle_bowl[counter]] = 0;
            if (prev_week_ID == 1)
                address_to_tickets_prev_week0[raffle_bowl[counter]] = 0;

            if (counter == raffle_bowl_counter)
                return true;

            counter++;
        }
    }

    function resetRaffle() public returns (int8 resetRaffle_STATUS)
    {
        /*  resetRaffle STATUS CODES:
            
            [-4] - Raffle still has tokens after fillBurner().
            [-3] - fillBurner() error.
            [-2] - getWinners() error.
            [-1] - We have no participants.
            [0 ] - ALL OK.
            [1 ] - Only one player, was refunded.
            [2 ] - Two players, were refunded.
            [3 ] - Three players, refunded.            */

        while (now >= next_week_timestamp)
        {
            next_week_timestamp += minutes_in_a_week * 1 minutes;
            current_week += 1;
        }

        if (raffle_bowl_counter == 0)
        {    /*   We have no registrants.  */
            resetWeeklyVars(); 
            return -1; /* Reset the stats and return */
        }

        if (unique_players < 4)
        {
            /* We have between 1 and three players in the raffle, refund their money. */
            for (uint x = 0; x < raffle_bowl_counter; x++)
            {
                /* And delete their tickets from the mapping */
                if (address_to_tickets[raffle_bowl[x]] != 0)
                    ERC20_CALLS.transfer(raffle_bowl[x], address_to_tickets[raffle_bowl[x]]*ticket_price);
            }

            resetWeeklyVars();
            /* Return 1, 2 or 3 depending on how many raffle players were refunded. */
            return int8(unique_players);
        }
        /* At this point we assume that we have more than three unique players. */
        getWinners(); /* Choose three winners */

        /* Do we have winners? */
        if ( (winner_1 == 0x0) || (winner_2 == 0x0) || (winner_3 == 0x0) )
            return -2;

        /* We have three winners! Proceed with rewards. */
        raffle_balance = ERC20_CALLS.balanceOf(raffle_addr);

        /* Transfer 40%, 20% and 10% of the tokens to their respective winners */ 
        ERC20_CALLS.transfer(winner_1, getPercent(40, raffle_balance));
        ERC20_CALLS.transfer(winner_2, getPercent(20, raffle_balance));
        ERC20_CALLS.transfer(winner_3, getPercent(10, raffle_balance));
        /* Burn 10%. */
        burnTenPercent(raffle_balance);

        /* Fill the burner with the rest of the tokens. */
        if (fillBurner() == -1)
            return -3; /* Burner addr NULL | error */ 

        /* Reset variables. */
        resetWeeklyVars();

        if (ERC20_CALLS.balanceOf(raffle_addr) > 0)
            return -4; /* We still have a positive balance | error */

        return 0; /* OK */
    }

    function getWinners() returns (uint getWinners_STATUS)
    {
        /* Acquire the first random number using previous blockhash as an initial seed. */
        uint initial_rand = getRand(seeds.length);

        /* Use this first random number to choose one of the seeds from the array. */
        uint firstwinner_rand = getRandWithSeed(seeds.length, seeds[initial_rand]);

        /* This new random number is used to grab the first winner's index from raffle_bowl. */
        winner_1 = raffle_bowl[firstwinner_rand];

        /* Acquire the second random number, while making sure it's not the same as a previous one. */
        /* We shall then generate a new seed by adding the second random number with a counter_seed! */
        uint counter_seed = firstwinner_rand+initial_rand;

        uint second_rand = uint(sha256(firstwinner_rand+initial_rand)) % seeds.length;

        while (true)
        {
            uint secondwinner_rand = uint(sha256(second_rand+counter_seed)) % seeds.length;
            winner_2 = raffle_bowl[secondwinner_rand];

            if (secondwinner_rand != firstwinner_rand)
            {
                if (winner_2 != winner_1)
                {
                    /* Repeat all of the steps for winner_1 once we have a unique player */
                    break;
                }
            }
            counter_seed += counter_seed;
        }
        //counter_seed += counter_seed;

        uint third_rand = uint(sha256(secondwinner_rand+counter_seed)) % seeds.length;

        while (true)
        {
            uint thirdwinner_rand = uint(sha256(third_rand+counter_seed)) % seeds.length;
            winner_3 = raffle_bowl[thirdwinner_rand];

            if ( (thirdwinner_rand != secondwinner_rand) && (thirdwinner_rand != firstwinner_rand) )
            {
                if ( (winner_3 != winner_1) && (winner_3 != winner_2) )
                {
                    break;
                }
            }
            counter_seed += counter_seed;
        }
        return 0;
    }

    function fillBurner() private returns (int8 fillBurner_STATUS)
    {
        /* [-1]: Burner Address NULL
        *  [ 0]: OK
        */
        if (burner_addr == 0x0)
            return -1;

        ERC20_CALLS.transfer(burner_addr, ERC20_CALLS.balanceOf(raffle_addr));
        return 0;
    }

    function fillWeeklyArrays(uint256 number_of_tickets, address user_addr) private returns (int8 fillWeeklyArrays_STATUS)
    {
        /*  [-1] Error with prev_week_ID
        *   [0]  OK                        */

        if ((prev_week_ID != 0) && (prev_week_ID != 1))
            return -1;

        /* If the address did not register tickets before, we will increment unique_players by one. */
        if (address_to_tickets[user_addr] == 0)
            unique_players++;

        address_to_tickets[user_addr] += number_of_tickets;
        
        if (prev_week_ID == 0)
            address_to_tickets_prev_week0[user_addr] += number_of_tickets;
        else if (prev_week_ID == 1)
            address_to_tickets_prev_week1[user_addr] += number_of_tickets;

        uint256 _ticket_number = number_of_tickets;
        while (_ticket_number > 0)
        {
            raffle_bowl[raffle_bowl_counter] = user_addr;
            raffle_bowl_counter += 1;
            _ticket_number -= 1;
        }
        /* Capture a seed from the user. */
        seeds.push(uint(sha256(user_addr)) * uint(sha256(now)));

        return 0;
    }

    function registerTickets(uint256 number_of_tickets) public returns (int8 registerTickets_STATUS)
    {
        /*  registerTickets RETURN CODES:

            [-6] - Raffle still has tickets after fillBurner() called 
            [-5] - fillBurner() null burner addr, raised error
            [-4] - fillWeeklyArrays() prev_week_ID invalid value, raised error.
            [-3] - getWinners() fail, raised error.
            [-2] - ACTUAL ALLOWANCE CHECK MISMATCH.
            [-1] - INVALID INPUT (zero or too many tickets).
            [0 ] - REGISTERED OK.                                   */

        /* Check the deadline */
        if (now >= next_week_timestamp)
        {
            int8 RAFFLE_STATUS = resetRaffle();

            if (RAFFLE_STATUS == -2)
                return -3; /* getWinners() errored, raise it! */

            if (RAFFLE_STATUS == -3)
                return -5; /* fillBurner() errored, raise it! */

            if (RAFFLE_STATUS == -4)
                return -6; /* Raffle still has tickets after fillBurner() called */
        }
        /* Before users will call registerTickets function,they will first have to call approve()    */
        /* on the XBL contract address and approve the Raffle to spend tokens on their behalf.      */
        /* After they have called approve, they will have to call this registerTickets() function  */

        /* Check for invalid inputs:                               */
        /* [!] Will have to revert() in cases of input errors [!] */
        if (number_of_tickets == 0)
            return -1;

        if (ERC20_CALLS.allowance(msg.sender, raffle_addr) < ticket_price * number_of_tickets)
            return -2;

        if (ERC20_CALLS.balanceOf(msg.sender) < ticket_price * number_of_tickets) 
            return - 2;

        /*  Reaching this point means the ticket registrant is legit  */
        /*  Every ticket will add an entry to the raffle_bowl         */
        if (fillWeeklyArrays(number_of_tickets, msg.sender) == -1)
            return -4; /* prev_week_ID invalid value */

        else
        {   /* Everything checks out, transfer the coins from the user to the raffle */
            ERC20_CALLS.transferFrom(msg.sender, raffle_addr, number_of_tickets * ticket_price);
            return 0; 
        }
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

    /* <<<--- Debug ONLY functions. These will be removed from the final version --->>> */
    /* <<<--- Debug ONLY functions. These will be removed from the final version --->>> */
    /* <<<--- Debug ONLY functions. These will be removed from the final version --->>> */

    function dSetXBLAddr(address _XBLContract_addr) public onlyOwner
    {
        /* Debugging purposes. This will be hardcoded in the original version. */
        XBLContract_addr = _XBLContract_addr;
        ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
        total_supply = ERC20_CALLS.totalSupply();
    }

    function dTestCallTotalSupply() public returns (uint256 total_supply)
    {
        return ERC20_CALLS.totalSupply();
    }

    function dTriggerNextWeekTimestamp() public
    {
        next_week_timestamp = now;
    }
}
