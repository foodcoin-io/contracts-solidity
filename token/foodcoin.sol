pragma solidity ^0.4.16;

// Безопасные математические функции
import './import/SafeMath.sol';
// описание функционала администрирования
import './import/Management.sol';

// Токен-контракт FoodCoin Ecosystem
contract FoodcoinEcosystem is SafeMath, Management {
	
	// название токена
	string public constant name = "FoodCoin EcoSystem";
	// короткое название токена
	string public constant symbol = "FOOD";
	// точность токена (знаков после запятой для вывода в кошельках)
	uint256 public constant decimals = 8;
	// общее кол-во выпущенных токенов
	uint256 public totalSupply = 0;
	
	// состояние счета
	mapping ( address => uint256 ) balances;
	// список всех счетов
	mapping ( uint256 => address ) public balancesListAddressMap;
	// соответсвие счета и его номера
	mapping ( address => uint256 ) public balancesListNumberMap;
	// текстовое описание счета
	mapping ( address => string ) public balancesAddressDescription;
	// общее кол-во всех счетов
	uint256 balancesCountInt = 1;
	
	// делегирование на управление счетом на определенную сумму
	mapping ( address => mapping ( address => uint256 ) ) allowed;
	
	
	// событие - транзакция
	event Transfer(address _from, address _to, uint256 _value, address _initiator);
	
	// событие делегирование управления счетом
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	// событие - эмиссия
	event TokenEmissionEvent( address initiatorAddress, uint256 amount, bool emissionOk );
	
	// событие - списание средств
	event WithdrawEvent( address initiatorAddress, address toAddress, bool withdrawOk, uint256 withdrawValue, uint256 newBalancesValue );
	
	
	// проссмотра баланса счета
	function balanceOf( address _owner ) external view returns ( uint256 )
	{
		return balances[ _owner ];
	}
	// Check if a given user has been delegated rights to perform transfers on behalf of the account owner
	function allowance( address _owner, address _initiator ) external view returns ( uint256 remaining )
	{
		return allowed[ _owner ][ _initiator ];
	}
	// общее кол-во счетов
	function balancesQuantity() external view returns ( uint256 )
	{
		return balancesCountInt - 1;
	}
	
	// функция непосредственного перевода токенов. Если это первое получение средств для какого-то счета, то также создается детальная информация по этому счету
	function _addClientAddress( address _balancesAddress, uint256 _amount ) internal
	{
		// check if this address is not on the list yet
		if ( balancesListNumberMap[ _balancesAddress ] == 0 )
		{
			// add it to the list
			balancesListAddressMap[ balancesCountInt ] = _balancesAddress;
			balancesListNumberMap[ _balancesAddress ] = balancesCountInt;
			// increment account counter
			balancesCountInt++;
		}
		// add tokens to the account 
		balances[ _balancesAddress ] = safeAdd( balances[ _balancesAddress ], _amount );
	}
	// Internal function that performs the actual transfer (cannot be called externally)
	function _transfer( address _from, address _to, uint256 _value ) internal isTransactionsOn returns ( bool success )
	{
		// If the amount to transfer is greater than 0, and sender has funds available
		if ( _value > 0 && balances[ _from ] >= _value )
		{
			// Subtract from sender account
			balances[ _from ] -= _value;
			// Add to receiver's account
			_addClientAddress( _to, _value );
			// Perform the transfer
			Transfer( _from, _to, _value, msg.sender );
			// Successfully completed transfer
			return true;
		}
		// Return false if there are problems
		else
		{
			return false;
		}
	}
	// функция перевода токенов
	function transfer(address _to, uint256 _value) external isTransactionsOn returns ( bool success )
	{
		return _transfer( msg.sender, _to, _value );
	}
	// функция перевода токенов с делегированного счета
	function transferFrom(address _from, address _to, uint256 _value) external isTransactionsOn returns ( bool success )
	{
		// Check if the transfer initiator has permissions to move funds from the sender's account
		if ( allowed[_from][msg.sender] >= _value )
		{
			// If yes - perform transfer 
			if ( _transfer( _from, _to, _value ) )
			{
				// Decrease the total amount that initiator has permissions to access
				allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
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
	// функция делегирования управления счетом на определенную сумму
	function approve( address _initiator, uint256 _value ) external isTransactionsOn returns ( bool success )
	{
		// Grant the rights for a certain amount of tokens only
		allowed[ msg.sender ][ _initiator ] = _value;
		// Initiate the Approval event
		Approval( msg.sender, _initiator, _value );
		return true;
	}
	
	// функция эмиссии (менеджер или владелец контракта создает токены и отправляет их на определенный счет)
	function tokenEmission(address _reciever, uint256 _amount) external isManagerOrOwner isEmissionOn returns ( bool returnVal )
	{
		// Check if it's a non-zero address
		require( _reciever != address(0) );
		// Calculate number of tokens after generation
		uint256 checkedSupply = safeAdd( totalSupply, _amount );
		// сумма к эмиссии
		uint256 amountTmp = _amount;
		// Если потолок эмиссии установлен, то нельзя выпускать больше этого потолка
		if ( tokenCreationCap > 0 && tokenCreationCap < checkedSupply )
		{
			amountTmp = 0;
		}
		// если попытка добавить больше 0-ля токенов
		if ( amountTmp > 0 )
		{
			// If no error, add generated tokens to a given address
			_addClientAddress( _reciever, amountTmp );
			// increase total supply of tokens
			totalSupply = checkedSupply;
			TokenEmissionEvent( msg.sender, _amount, true);
		}
		else
		{
			returnVal = false;
			TokenEmissionEvent( msg.sender, _amount, false);
		}
	}
	
	// функция списания токенов
	function withdraw( address _to, uint256 _amount ) external isSpecialManagerOrOwner returns ( bool returnVal, uint256 withdrawValue, uint256 newBalancesValue )
	{
		// check if this is a valid account
		if ( balances[ _to ] > 0 )
		{
			// сумма к списанию
			uint256 amountTmp = _amount;
			// нельзя списать больше, чем есть на счету
			if ( balances[ _to ] < _amount )
			{
				amountTmp = balances[ _to ];
			}
			// проводим списывание
			balances[ _to ] = safeSubtract( balances[ _to ], amountTmp );
			// меняем текущее общее кол-во токенов
			totalSupply = safeSubtract( totalSupply, amountTmp );
			// возвращаем ответ
			returnVal = true;
			withdrawValue = amountTmp;
			newBalancesValue = balances[ _to ];
			WithdrawEvent( msg.sender, _to, true, amountTmp, balances[ _to ] );
		}
		else
		{
			returnVal = false;
			withdrawValue = 0;
			newBalancesValue = 0;
			WithdrawEvent( msg.sender, _to, false, _amount, balances[ _to ] );
		}
	}
	
	// добавление описания к счету
	function balancesAddressDescriptionUpdate( string _newDescription ) external returns ( bool returnVal )
	{
		// если такой аккаунт есть или владелец контракта
		if ( balancesListNumberMap[ msg.sender ] > 0 || ownerAddressMap[msg.sender]==true )
		{
			balancesAddressDescription[ msg.sender ] = _newDescription;
			returnVal = true;
		}
		else
		{
			returnVal = false;
		}
	}
}