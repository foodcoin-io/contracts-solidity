pragma solidity ^0.4.16;

// Importing library with math utility functions
import './import/SafeMath.sol';
// Importing token prototype
import './import/Token.sol';
// Importing Ownable contract, that allows FoodCoin contract to have several independent administrators
import './import/Ownable.sol';
// Importing object for logging of token operations
import './import/Logging.sol';
// Importing object needed for contract deletion
import './import/Destructible.sol';

// Begin main body of the contract
contract FoodCoin is SafeMath, Token, Logging, Destructible {
	// Begin token description	
	// Full Name
	string public constant name = "FoodCoin EcoSystem";

	// Abbreviated name (ticker)
	string public constant symbol = "FOOD";

	// Number of decimal points used by a token (in case of FoodCoin only integer values are used)
	uint256 public constant decimals = 0;
	
	// End of token description
	
	// Smart Contract events (in addition to the ones inherited from parent obkects)
	// Distribution of tokens to the owner
	event CreateFOOD( address addressOwner, address to, uint amount );

	// Transfer specific number of tokens (_value parameter) from sender (_from parameter) to recipient (_to parameter) potentially initiated by a third-party (_initiator parameter).  Initiator could be the same person as sender.
	event Transfer(address _from, address _to, uint256 _value, address _initiator);
	
	// Events that are responsible for the end of Token Distribution Event (TDE)
	
	// Event that takes place at the end of the TDE
	event TDEStop( uint timestamp );

	// Event that takes place when one of the administrators votes to end the TDE
	event TDEStopVote(address ownerAddress, uint timestamp );
		
	// List of administrators voting for the end of TDE
	address[] TDEStopVoteList;
		
	// Number of votes needed to end the TDE
	uint8 TDEStopCountMax = 2;
		
	// Current state of TDE
	// TRUE	 = TDE stopped successfully, owners can exchange tokens, maximum number of tokens distributed during TDE is set
	// FALSE = TDE is not yet complete, participants cannot trade tokens
	bool TDEStopOn = false;
		
	// function modifier - checks if TDE has not been stopped 
	modifier whenNotTDEStop()
	{
		require( !TDEStopOn );
		_;
	}
		
	// function modifier - checks if TDE has been stopped
	modifier whenTDEStop()
	{
		require( TDEStopOn );
		_;
	}
		
	// Process contract owner votes to stop the TDE, lock the exchange rate and allow token trading (used by contract owners)
	function TDEStopVoteGo() external onlyOwner whenNotTDEStop
	{
		// If there are no votes yet to to stop the TDE
		if ( TDEStopVoteList.length == 0 )
		{
			// Add function caller as the first vote
			TDEStopVoteList.push( msg.sender );
			// Log the fact that vote has been recorded
			TDEStopVote( msg.sender, now );
		}
		// Else - there are some votes that have been recorded already
		else
		{
			uint8 iOk = 0;
			// Loop through all the recorded votes
			for ( uint i = 0; i < TDEStopVoteList.length; i++ )
			{
				// If the current voter did not yet vote, record the vote and  
				if ( msg.sender != TDEStopVoteList[ i ] )
				{
					iOk++;
				}
			}
			if ( iOk >= TDEStopVoteList.length )
			{
				// Add function caller as the recorded vote
				TDEStopVoteList.push( msg.sender );
				// Log the fact that vote has been recorded
				TDEStopVote( msg.sender, now );
			}
		}
			
		// If the number of votes is equal to or greater the number needed to stop the TDE
		if ( TDEStopVoteList.length >= TDEStopCountMax )
		{
			// Mark TDE as stopped
			TDEStopOn = true;
			// Calculate total supply of tokens (total number of tokens issued during TDE represents 9% of total supply ever available)
			tokenCreationCap = safeDiv( safeMult( totalSupply, 10000 ), 900 );
			// Initiate the stop TDE event
			TDEStop( now );
		}
	}
	
	// Implementation and extensions of standard token functions 
	
		// Token balance at a given address
		mapping ( address => uint256 ) balances;
		
		// Allow user to control someone else's token balance (up to a certain token limit)
		mapping ( address => mapping ( address => uint256 ) ) allowed;
		
		// mapping, containing full list of accounts and their token balances - used to export the list into an external system 
		mapping ( uint256 => address ) balancesListAddress;
		
		// total number of accounts
		uint256 public balancesListAddressCount = 0;
		
		// object containing detailed account information
		struct ClientInfo
		{
			// account serial number
			uint256 listNumber;
			// date when account was created
			uint256 addTimestamp;
			// creator's address
			address addAddress;
			// Internal ID on foodcoin.io
			string extId;
			// associated email address
			string extEmail;
		}
		// mapping containing a list of all accounts
		mapping ( address => ClientInfo ) clientInfoList;
		
		// Adding tokens to user's account, and add account to the list if not previously present
		function _addClientAddress( address _clientAddress, uint256 _amount, string _extId, string _extEmail ) internal
		{
			// check if this address is not on the list yet
			if ( clientInfoList[ _clientAddress ].addTimestamp <= 0 )
			{
				// add it to the list
				balancesListAddress[ balancesListAddressCount ] = _clientAddress;
				// create an object with account information
				clientInfoList[ _clientAddress ] = ClientInfo({
					listNumber: balancesListAddressCount,
					addTimestamp: now,
					addAddress: msg.sender,
					extId: _extId,
					extEmail: _extEmail
				});
				// increment account counter
				balancesListAddressCount++;
			}
			// add tokens to the account 
			balances[ _clientAddress ] += _amount;
		}
		
		// get account informaton by pulling it from the list
		function getNumberAddress( uint256 _getNumberInfo ) constant onlyOwner returns ( address )
		{
			return balancesListAddress[ _getNumberInfo ];
		}
		
		// return detailed account information by address
		function getAccountInfo( address _getAddress ) constant onlyOwner returns ( uint256 listNumber, uint256 addTimestamp, string extId, string extEmail, address addAddress)
		{
			// verify that this is a valid account first and if it's present in the list of accounts
			require( clientInfoList[ _getAddress ].addTimestamp > 0 );
			// return detailed informaton 
			listNumber = clientInfoList[ _getAddress ].listNumber;
			addTimestamp = clientInfoList[ _getAddress ].addTimestamp;
			extId = clientInfoList[ _getAddress ].extId;
			extEmail = clientInfoList[ _getAddress ].extEmail;
			addAddress = clientInfoList[ _getAddress ].addAddress;
		}
			
		// Internal function that performs the actual transfer (cannot be called externally)
		function _transfer( address _from, address _to, uint256 _value ) internal returns ( bool success )
		{
			// If the amount to transfer is greater than 0, and sender has funds available
			if ( _value > 0 && balances[ _from ] >= _value )
			{
				// Subtract from sender account
				balances[ _from ] -= _value;
				// Add to receiver's account
				_addClientAddress( _to, _value, '', '' );
				// Perform the transfer
				Transfer( _from, _to, _value, msg.sender );
				// Log the transaction
				addLog(  msg.sender, _to, _value );
				// Successfully completed transfer
				return true;
			}
			// Return false if there are problems
			else
			{
				return false;
			}
		}
		
		// Returns a balance on a given account
		function balanceOf( address _owner ) constant returns ( uint256 )
		{
			return balances[ _owner ];
		}
	
		// External function to transfer funds from sender to recipient.  Valid only after the end of TDE.
		function transfer(address _to, uint256 _value) whenTDEStop returns ( bool success )
		{
			return _transfer( msg.sender, _to, _value );
		}
		
		// Redefinition of the strandard transfer function to include support for delegated transfers
		function transferFrom(address _from, address _to, uint256 _value) whenTDEStop returns (bool success)
		{
			// Check if the transfer initiator has permissions to move funds from the sender's account
			if ( allowed[_from][msg.sender] >= _value )
			{
				// If yes - perform transfer 
				if ( _transfer( msg.sender, _to, _value ) )
				{
					// Decrease the total amount that initiator has permissions to access
					allowed[_from][msg.sender] -= _value;
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
		}
		
		// Grant a user rights to perform transfers on behalf of an account holder.  Function is always called by an account holder.  
		function approve(address _initiator, uint256 _value) whenTDEStop returns (bool success)
		{
			// Grant the rights for a certain amount of tokens only
			allowed[ msg.sender ][ _initiator ] = _value;
			// Initiate the Approval event
			Approval(msg.sender, _initiator, _value);
			return true;
		}
		
		// Check if a given user has been delegated rights to perform transfers on behalf of the account owner
		function allowance(address _owner, address _initiator) constant returns (uint256 remaining)
		{
			return allowed[ _owner ][ _initiator ];
		}
		
		// Generate tokens for a given recipient
		function generateTokens(address _reciever, uint256 _amount, string _extId, string _extEmail) external onlyOwner
		{
			// Check if it's a non-zero address
			require( _reciever != address(0) );
			// If TDE hasn't closed yet, there are no limits on the number tokens being generated
			if ( !TDEStopOn )
			{
				// Add tokens to a given address
				_addClientAddress( _reciever, _amount, _extId, _extEmail );
				// increase total supply of tokens
				totalSupply = safeAdd( totalSupply, _amount );
				// Initiate the event notification for the token generation
				CreateFOOD( msg.sender, _reciever, _amount );
				// log the token generation data
				addLog( msg.sender, _reciever, _amount );
			}
			// If TDE has ended, then total number of tokens is limited, so need to check against the maximi available supply of tokens
			else
			{
				// Calculate number of tokens after generation
				uint256 checkedSupply = safeAdd( totalSupply, _amount );
				// Throw an error if the new number exceed maximum available tokens
				require( tokenCreationCap < checkedSupply );
				// If no error, add generated tokens to a given address
				_addClientAddress( _reciever, _amount, _extId, _extEmail );
				// increase total supply of tokens
				totalSupply = checkedSupply;
				// Initiate the event notification for the token generation
				CreateFOOD( msg.sender, _reciever, _amount );
				// log the token generation data
				addLog( msg.sender, _reciever, _amount );
			}
		}
	
	
	// Contract management section - currently used to delete the contract
	
		// Event: Vote recorded to delete the contract 
		event VoteForDeletionContractSet( address ownerAddress, uint timestamp );
	
		// List of admins that voted to remove an admin
		address[] votedOwnerForDeletion;
		
		// Number of votes needed to delete the contract
		uint8 votedOwnerForDeletionCountMax = 2;
	
		// Vote to delete contract
		function voteForDeletionContract() external onlyOwner
		{
			// If no other votes recorded - records this one
			if (votedOwnerForDeletion.length == 0)
			{
				votedOwnerForDeletion.push( msg.sender );
				VoteForDeletionContractSet( msg.sender, now );
			}
			// If other votes have been recorded - attempt to add another vote
			else
			{
				// Check all recorded votes, then if this vote is not found already, record it
				uint8 iOk = 0;
				for (uint i = 0; i < votedOwnerForDeletion.length; i++)
				{
					if ( msg.sender != votedOwnerForDeletion[i] )
					{
						iOk++;
					}
				}
				if ( iOk >= votedOwnerForDeletion.length )
				{
					votedOwnerForDeletion.push( msg.sender );
					VoteForDeletionContractSet( msg.sender, now );
				}
			}
			
			// If enough votes have been recorded to delete the contract, proceed with deletion 
			if ( votedOwnerForDeletion.length >= votedOwnerForDeletionCountMax )
			{
				destroy();
			}
		}
	
	
	// Transactions to write off, or retire tokens.  This needs to be approved by multiple administrators.	
	
		// Event: request to write off tokens
		event CreatureTransactionWriteOff( address ownerAddress, uint timestamp, address to, uint value, uint8 votedval, uint number );
	
		// Event: vot cast to write off tokens 
		event VotedTransactionWriteOff( address ownerAddress, uint timestamp, uint number, uint counVoted );
		
		// Event: tokens have been written off
		event TransactionWriteOffEnd( address toAddress, uint timestamp, uint number, uint counVoted, uint writeOff1, uint writeOff2 );
	
		// minimum number of votes needed for write off
		uint8 votedOwnerForTransactionWriteOff = 2;
		
		// Object definition for writing off tokens
		struct TransactionWriteOff
		{
			// account address from which tokens are being written off
			address to;
			// total amount being written off
			uint value;
			// number of votes needed to write off tokens
			uint8 votedMax;
			// current transaction status (Executed: Yes/No)
			bool notExecuted;
			// list of admins that voted on the transaction
			address[] votedOwnerOn;
		}
		// lsit of write off transactions
		mapping ( uint => TransactionWriteOff ) public transactionWriteOffList;
		// total number of written off transactions
		uint transactionWriteOffListCount = 0;
		
		// empty array that will be used in a struct to collect admins that have voted for the transaction
		address[] arrayNullAddress;
		
		// Create a write off transaction and add it to the pool for voting by admins
		function addTransactionWriteOff( address _to, uint _value, uint8 _votedMax ) onlyOwner returns ( uint transactionWriteOffNumber )
		{
			// check if this is a valid account
			require( balances[ _to ] > 0 );
			
			// generate unique transaction number (based on the existing count of such transactions)
			transactionWriteOffNumber = transactionWriteOffListCount;
			transactionWriteOffListCount += 1;
			
			// set the minimum number of admins that need to vote on the transaction
			if ( _votedMax < votedOwnerForTransactionWriteOff ) _votedMax = votedOwnerForTransactionWriteOff;
			
			// add transaction to the list
			transactionWriteOffList[ transactionWriteOffNumber ] = TransactionWriteOff({
				to : _to,
				value : _value,
				votedMax: _votedMax,
				notExecuted : true,
				votedOwnerOn: arrayNullAddress
			});
			
			// add the first voter for the transaction - the admin that initiated it
			transactionWriteOffList[ transactionWriteOffNumber ].votedOwnerOn.push( msg.sender );
			
			// Initiate the Write Off event
			CreatureTransactionWriteOff( msg.sender, now, _to, _value, _votedMax, transactionWriteOffNumber );
		}
		
		// process vote to approve write off transaction
		function votedTransactionWriteOff( uint _transactionNumber ) onlyOwner
		{
			// check if the transaction actually exists and if it hasn't executed yet
			require( transactionWriteOffList[ _transactionNumber ].notExecuted );
			
			// loop through all admins that have voted, and if the current admin hasn't voted yet - add their vote to the list
			uint8 iOk = 0;
			for (uint i = 0; i < transactionWriteOffList[ _transactionNumber ].votedOwnerOn.length; i++)
			{
				if ( msg.sender != transactionWriteOffList[ _transactionNumber ].votedOwnerOn[ i ] )
				{
					iOk++;
				}
			}
			if ( iOk >= TDEStopVoteList.length )
			{
				// add to the list
				transactionWriteOffList[ _transactionNumber ].votedOwnerOn.push( msg.sender );
				// Initiate vote received event
				VotedTransactionWriteOff( msg.sender, now, _transactionNumber, transactionWriteOffList[ _transactionNumber ].votedOwnerOn.length );
			}
			
			// check if we have enough votes, if so - perform the write off
			if ( transactionWriteOffList[ _transactionNumber ].votedOwnerOn.length >= transactionWriteOffList[ _transactionNumber ].votedMax )
			{
				// get the value being written off
				uint writeOffvalue = transactionWriteOffList[ _transactionNumber ].value;
				// compare if with the account balance, cannot write off more than the balance on the account 
				if ( balances[ transactionWriteOffList[ _transactionNumber ].to ] < writeOffvalue ) writeOffvalue = balances[ transactionWriteOffList[ _transactionNumber ].to ];
				// subtract the write off amount
				balances[ transactionWriteOffList[ _transactionNumber ].to ] = balances[ transactionWriteOffList[ _transactionNumber ].to ] - writeOffvalue;
				// decrease total supply of available tokens across all acounts
				totalSupply = totalSupply - writeOffvalue;
				// Initiate Write Off event
				TransactionWriteOffEnd( transactionWriteOffList[ _transactionNumber ].to, now, _transactionNumber, transactionWriteOffList[ _transactionNumber ].votedOwnerOn.length, transactionWriteOffList[ _transactionNumber ].value, writeOffvalue );
			}
		}
}
	
