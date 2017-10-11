pragma solidity ^0.4.17;

contract Owned {
    address public owner;
    
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public {
        owner = newOwner;
    }
}

contract Lottery is Owned {
    
    address[] public tickets;  //Might need to somehow initialize this array to a size
    //Used mostly for reset of the lottery so we don't have to search the
    //full array to reset the isBought bools
    uint public numBought;
    
    uint public etherPool;    //In wei
    uint public minJackpot;   //In wei
    uint public ticketPrice;  //In wei
    uint public numTickets;
    
    uint etherFundingPool;
    bool jackPotReached;
    
    event LotteryEnded(bool winnerExists, address winner, uint prize);
    event NewLotteryBegun(uint prize);
    event MinJackpotReached();
    
    function Lottery(uint _minJackpot, uint _ticketPrice, uint _numTickets) public {
        numBought = 0;
        
        etherPool = 0;
        minJackpot = _minJackpot;
        ticketPrice = _ticketPrice;
        numTickets = _numTickets;
        
        jackPotReached = false;
    }
    
    function buyTickets() public payable {  
        //Make sure they are paying exact change for a number of tickets and 
        //that the lottery is currently being held
        require(msg.value >= ticketPrice);
        
        //uint change = msg.value % ticketPrice;
        uint ticketsBought = msg.value / ticketPrice;
        //if ((ticketsBought + numBought) > numTickets) {
        //    change += (ticketsBought + numBought - numTickets) * ticketPrice;
        //}
        
        for (uint i=0; i<ticketsBought; i++) {
            tickets[numBought] = msg.sender;
            numBought++;
            if (numBought >= numTickets) {
                break;
            }
        }
        
        //if (change > 0) {
        //    msg.sender.transfer(change);
        //}
        
        //Reflect the purchases in the pool
        etherPool += ((msg.value * 9) / 10);
        etherFundingPool += (msg.value / 10);
        
        //Check to trigger event for reaching minimum pool
        if(!jackPotReached && (etherPool > minJackpot)) {
            jackPotReached = true;
            MinJackpotReached();   //Call event
        }
    }
    
    function endLottery() public onlyOwner {
        
        require(jackPotReached);
        
        /////////////////////////////////////////////
        //Take a current or specific block hash and//
        //divide by the number of tickets in the   //
        //lottery.  Remainder is the winning ticket//
        /////////////////////////////////////////////
        uint winningTicket = block.number % numTickets;
        
        address winner = 0; //TODO do we need both winner and isWinner?
        bool isWinner = false;
        if (winningTicket < numBought) {
            winner = tickets[winningTicket];
            isWinner = true;
        }
        
        LotteryEnded(isWinner, winner, etherPool);
        
        if(isWinner) {
            winner.transfer(etherPool);
            owner.transfer(etherFundingPool);
            etherPool = 0;
            etherFundingPool = 0;
        } 
        
    }
    
    function restartLottery(uint _minJackpot, 
                            uint _ticketPrice, 
                            uint _numTickets) public onlyOwner {  
        //Reset all the values
        minJackpot = _minJackpot;   
        ticketPrice = _ticketPrice;  
        numTickets = _numTickets;
    
        jackPotReached = false;
    
        //Reset the tickets
        numBought = 0;
    
        //Alert watchers
        NewLotteryBegun(etherPool);
    }
    
    function Die() public onlyOwner {
        selfdestruct(owner);
    }
    
}
