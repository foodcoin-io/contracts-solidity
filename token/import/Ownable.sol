/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	
	// List of owner records.  The list is checked against when contract needs to know if an address is a valid owner of tokens.
    mapping (address => bool) public isOwner;
	// Corresponding array with all valid owner addresses.  Used to iterate to be able to find if a particular address belongs to a valid owner
    address[] owners;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.  
     */
    function Ownable() {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
    }

    /**
     * modifier that will break function execution if passed parameter belongs to an existing owner
     */
    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
        revert();
        _;
    }

    /**
     * modifier that will break function execution if passed parameter does not belong to an existing owner
     */
    modifier ownerExists(address owner) {
        if (!isOwner[owner])
        revert();
        _;
    }

    // @dev Returns list of owners.
    // @return List of all owner addresses.
    function getOwners()
    public
    constant
    returns (address[])
    {
        return owners;
    }


    /**
     * @dev Allows the current owner to add a newOwner.
     * @param newOwner The address for add new owner.
	 * Function is used to add another owner (administrator) by an existing administrator. 
     */
    function addOwner(address newOwner) external onlyOwner ownerDoesNotExist(newOwner) {
        require(newOwner != address(0));
        isOwner[newOwner] = true;
        owners.push(newOwner);
    }

}