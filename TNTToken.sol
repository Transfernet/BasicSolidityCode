pragma solidity ^0.4.2;
contract owned {
    address public owner;

    /* The creator of this token becomes the owner */
    function owned() public {
        owner = msg.sender;
    }

    /* Only the owner can do things with this modifier */
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    /* You can transfer ownership to another address */
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

    /* Called by approveAndCall */
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    /* Keep record of users asking for approval of spending tokens for other contracts */
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require (balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
            
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) 
        public returns (bool success) {
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require (_value <= allowance[msg.sender][_from]);    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public { //???WHY and HOW???
        revert();     // Prevents accidental sending of ether
    }
}

contract TNTToken is owned, token { // MyAdvancedToken is owned by the creator, and inherits the token contract

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public approvedAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function TNTToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) public {
        if(centralMinter != 0 ) owner = centralMinter;      // Sets the owner as specified (or msg.sender if centralMinter is not specified)
        balanceOf[owner] = initialSupply;                   // Give the owner all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require (_to != 0x0);                               // Prevent transfer to empty address
	    require (approvedAccount[msg.sender]);
        require (balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require (approvedAccount[msg.sender]);                // Check if frozen
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) 
        public returns (bool success) {
        
        require (approvedAccount[_from]);                    // Check if frozen            
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require (_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[msg.sender][_from] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        approvedAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value);
	    balanceOf[msg.sender] -= _value;
	    totalSupply -= _value;
	    Burn(msg.sender, _value);
	    return true;
    }

    function burnFrom(address _from, uint _value) onlyOwner public payable returns (bool success) {
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
	    require (_value <= allowance[_from][msg.sender]);   // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the sender
        totalSupply -= _value;                              // Subtract from the total supply
        Burn(_from, _value);
        return true;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public returns (uint){
        uint amount = msg.value / buyPrice;                // calculates the amount
        require (balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
	return amount;
    }

    function sell(uint256 amount) public {
        require (balanceOf[msg.sender] >= amount );        // checks if the sender has enough to sell
        balanceOf[this] += amount;                         // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
        if (!msg.sender.send(amount * sellPrice)) {        // sends ether to the seller. It's important
            revert();                                      // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
        }               
    }

    function thresholdPrice(uint256 amount) public onlyOwner { // Only the owner can set the threshold price
        // Currently empty, since there should be a set threshold that will increase the price
	/*
	if (totalSupply <= 0) throw;
        if (totalSupply < #####)
	    setPrices(sellPrice + #####, buyPrice + #####);
	*/
    }
}
