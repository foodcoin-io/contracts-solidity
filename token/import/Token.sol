/*
	Protototype of a token smart contract
*/
contract Token {
	// total number of tokens currently avaiable
	uint256 public totalSupply;
	// limit on the maximum number of tokens that will be issued 
	uint256 public tokenCreationCap = 0;
	// number of tokens at a given account
	function balanceOf(address _owner) constant returns (uint256 balance);
	// transfer tokens from the calling account to another account
	function transfer(address _to, uint256 _value) returns (bool success);
	// transfer tokens from one account to another (delegated transfer)
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
	// approve delegation of token management - allow another user to transfer up to _value tokens to any destination
	function approve(address _spender, uint256 _value) returns (bool success);
	// check how many tokens can one account transfer from the owner to external account
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);
	// Event defintion: transfer  tokens
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	// Event defintion: approval to perform transfers on behalf of another user
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}