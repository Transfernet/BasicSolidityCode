pragma solidity ^0.4.0;

contract Owned {
    address public owner;
    
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() public {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Lottery is Owned {
    
    struct Ticket {
        address owner;
        bool isBought;
        uint timeOfPurchase;
    }
    Ticket[] tickets;  //Might need to somehow initialize this array to a size
    //Used mostly for reset of the lottery so we don't have to search the
    //full array to reset the isBought bools
    uint[] boughtTickets;
    uint numBought;
    
    uint public startTime;    //Maybe use lower uints (this is 256)
    uint public minLotteryLength;  // = 2 weeks TODO
    uint public etherPool;    //In wei
    uint public minJackpot;   //In wei
    uint public ticketPrice;  //In wei
    uint public numTickets;
    
    uint etherFundingPool;
    bool timeLimitReached;
    bool jackPotReached;
    
    event LotteryEnded(bool winnerExists, address winner, uint prize);
    event NewLotteryBegun(uint prize);
    event MinJackpotReached();
    
    function Lottery(uint _lotteryLength, uint _minJackpot, 
                        uint _ticketPrice, uint _numTickets) {
        numBought = 0;
        
        startTime = now;
        minLotteryLength = _lotteryLength;
        etherPool = 0;
        minJackpot = _minJackpot;
        ticketPrice = _ticketPrice;
        numTickets = _numTickets;
        
        timeLimitReached = false;
        jackPotReached = false;
    }
    
    function buyTickets(uint[] _tickets) payable {  
        //Make sure they are paying exact change for a number of tickets and 
        //that the lottery is currently being held
        require(now <= startTime + minLotteryLength);
        require(msg.value >= _tickets.length * ticketPrice);
        
        uint change = msg.value - _tickets.length * ticketPrice;
        
        for (uint i=0; i<_tickets.length; i++) {
            require(_tickets[i] < numTickets);
            if (!tickets[_tickets[i]].isBought) {
                tickets[_tickets[i]].owner = msg.sender;
                tickets[_tickets[i]].isBought = true;
                tickets[_tickets[i]].timeOfPurchase = now;
                boughtTickets[numBought] = _tickets[i];
                numBought++;
            } else {
                //Tell the purchaser somehow TODO
                //Send them back the money for that ticket
                msg.sender.transfer(change);
            }
        }
        
        //Reflect the purchases in the pool
        etherPool += msg.value * 9 / 10;
        etherFundingPool += msg.value / 10;
        if (change != 0) {
            msg.sender.transfer(change);
        }
        
        //Check to trigger event for reaching minimum pool
        if(!jackPotReached && (etherPool > minJackpot)) {
            jackPotReached = true;
            MinJackpotReached();   //Call event
            if (timeLimitReached) {
                endLottery();
            }
        }
    }
    
    function endLottery() onlyOwner {
        //Ensure it's time to end
        require(now >= startTime + minLotteryLength);  
        //TODO These timeLimitReached and minJackpotReached bools might need work
        
        //Check that the pool reached the minimum for payout
        if (etherPool < minJackpot) {
            timeLimitReached = true;
            return;
        }
        
        /////////////////////////////////////////////
        //Take a current or specific block hash and//
        //divide by the number of tickets in the   //
        //lottery.  Remainder is the winning ticket//
        /////////////////////////////////////////////
        uint winningTicket = block.number % numTickets;
        
        address winner = 0; //TODO do we need both winner and isWinner?
        bool isWinner = false;
        for (uint i=0; i<numBought; i++) {
            if (boughtTickets[i] == winningTicket) {
                winner = tickets[winningTicket].owner;
                isWinner = true;
            }
        }
        
        LotteryEnded(isWinner, winner, etherPool);
        
        if(isWinner) {
            winner.transfer(etherPool);
            owner.transfer(etherFundingPool);
            etherPool = 0;
            etherFundingPool = 0;
        } 
        
    }
    
    function restartLottery(uint _minLotteryLength, 
                            uint _minJackpot, 
                            uint _ticketPrice, 
                            uint _numTickets) onlyOwner {  //Needs work TODO
        //Reset all the values
        startTime = now;
        minLotteryLength = _minLotteryLength;
        minJackpot = _minJackpot;   
        ticketPrice = _ticketPrice;  
        numTickets = _numTickets;
    
        timeLimitReached = false;
        jackPotReached = false;
    
        //Reset the tickets
        for (uint i=0; i<numBought; i++) {
            tickets[boughtTickets[i]].isBought = false;
        }
        numBought = 0;
    
        //Alert watchers
        NewLotteryBegun(etherPool);
    }
    
}
