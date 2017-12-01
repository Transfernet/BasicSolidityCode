pragma solidity ^0.4.17;

contract Lottery {
    address[] tickets;
    uint public numBought;
    
    address public owner;
    
    uint public etherPool;
    uint public fundingPool;
    uint public minJackpot;
    uint public ticketPrice;
    uint public numTickets;
    
    bool public jackpotReached;
    
    function Lottery(uint _minJackpot, 
                     uint _ticketPrice, 
                     uint _numTickets) public {
        
        numBought = 0;
        
        owner = msg.sender;
        
        etherPool = 0;
        fundingPool = 0;
        minJackpot = _minJackpot;
        ticketPrice = _ticketPrice;
        numTickets = _numTickets;
        
        jackpotReached = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function buyTickets() public payable {
        require(msg.value >= ticketPrice);
        
        uint ticketsBought = msg.value / ticketPrice;
        uint change = msg.value % ticketPrice;
        for (uint i=0; i<ticketsBought; i++) {
            tickets.push(msg.sender);
            numBought++;
        }
        
        uint value = ticketsBought * ticketPrice;
        etherPool += value * 9 / 10;
        fundingPool += value / 10;
        
        if (change > 0) {
            msg.sender.transfer(change);
        }
        
        if (etherPool >= minJackpot) {
            jackpotReached = true;
        }
    }
    
    function RestartLottery(uint _minJackpot, 
                            uint _ticketPrice, 
                            uint _numTickets) public onlyOwner {
        
        require(jackpotReached);
        
        uint winningTicket = block.number % numTickets;
        
        address winner = 0;
        bool isWinner = false;
        if(winningTicket < numBought) {
            winner = tickets[winningTicket];
            isWinner = true;
        }
        
        if(isWinner) {
            winner.transfer(etherPool);
            owner.transfer(fundingPool);
            etherPool = 0;
            fundingPool = 0;
            numBought = 0;
            jackpotReached = false;
        }
        
        if (_minJackpot > 0) {
            minJackpot = _minJackpot;
        }
        if (_ticketPrice > 0) {
            ticketPrice = _ticketPrice;
        }
        if (_numTickets > 0) {
            numTickets = _numTickets;
        }
    }
    
    function TransferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}
