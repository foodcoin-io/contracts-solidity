/*
	Object that defines inherited behavior to allow deletion of a contract
*/

contract Destructible is Ownable {

	function Destructible() payable {}

	/**
	* @dev Transfers the current balance to the owner and terminates the contract.
	*/
	function destroy() internal onlyOwner
	{
		selfdestruct(msg.sender);
	}
}