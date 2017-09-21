/*
	Object that defines inherited behavior for transaction logging 
*/

contract Logging {
	
	// Number of lines logged
	uint public logCounter;

	// Large publci table containing log records
	mapping (uint => Log) public logs;

	// Definition of an individual log record
	struct Log {
		// Creation timestamp
		uint timestamp;
		// Account for which log was recorded
		address from;
		// Transaction transfer destination
		address to;
		// Transaction amount
		uint amount;
	}

	// Function recording log records into the log table
	function addLog( address from, address to, uint amount )
	{
		logs[logCounter] = Log( now, from, to, amount );
		logCounter += 1;
	}
}