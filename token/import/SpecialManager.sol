/*
	Управление специальными менеджерами
	Специальный менеджер может проводить списание токенов и менять текст-описания контракта
*/
pragma solidity ^0.4.16;

import './Owner.sol';

contract SpecialManager is Owner {

	// адреса специальных менеджеров
	mapping ( address => bool ) public specialManagerAddressMap;
	// Соответсвие адреса специального менеджера и его номера
	mapping ( address => uint256 ) public specialManagerAddressNumberMap;
	// список специальноых менеджеров
	mapping ( uint256 => address ) public specialManagerListMap;
	// сколько всего специальных менеджеров
	uint256 public specialManagerCountInt = 0;
	
	// модификатор - если смотрит владелец или специальный менеджер
	modifier isSpecialManagerOrOwner {
        require( specialManagerAddressMap[msg.sender]==true || ownerAddressMap[msg.sender]==true );
        _;
    }
	
	// создание/включение специального менеджера
	function specialManagerOn( address _onSpecialManagerAddress ) external isOwner returns (bool retrnVal) {
		// Check if it's a non-zero address
		require( _onSpecialManagerAddress != address(0) );
		// если такой менеджер есть
		if ( specialManagerAddressNumberMap[ _onSpecialManagerAddress ]>0 )
		{
			// если такой менеджер отключен, влючим его обратно
			if ( !specialManagerAddressMap[ _onSpecialManagerAddress ] )
			{
				specialManagerAddressMap[ _onSpecialManagerAddress ] = true;
				ContractManagementUpdate( "Special Manager", msg.sender, _onSpecialManagerAddress, true );
				retrnVal = true;
			}
			else
			{
				retrnVal = false;
			}
		}
		// если такого менеджера нет
		else
		{
			specialManagerAddressMap[ _onSpecialManagerAddress ] = true;
			specialManagerAddressNumberMap[ _onSpecialManagerAddress ] = specialManagerCountInt;
			specialManagerListMap[ specialManagerCountInt ] = _onSpecialManagerAddress;
			specialManagerCountInt++;
			ContractManagementUpdate( "Special Manager", msg.sender, _onSpecialManagerAddress, true );
			retrnVal = true;
		}
	}
	
	// отключение менеджера
	function specialManagerOff( address _offSpecialManagerAddress ) external isOwner returns (bool retrnVal) {
		// если такой менеджер есть и он не 0-вой, а также активен
		// 0-вой менеджер не может быть отключен
		if ( specialManagerAddressNumberMap[ _offSpecialManagerAddress ]>0 && specialManagerAddressMap[ _offSpecialManagerAddress ] )
		{
			specialManagerAddressMap[ _offSpecialManagerAddress ] = false;
			ContractManagementUpdate( "Special Manager", msg.sender, _offSpecialManagerAddress, false );
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}


	// конструктор, добавляет создателя в суперменеджеры
	function SpecialManager() public {
		// создаем менеджера
		specialManagerAddressMap[ msg.sender ] = true;
		specialManagerAddressNumberMap[ msg.sender ] = specialManagerCountInt;
		specialManagerListMap[ specialManagerCountInt ] = msg.sender;
		specialManagerCountInt++;
	}
}