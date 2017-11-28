/*
	Управление менеджерами контракта
	Менеджер - можем только создавать эмиссию и смотреть некоторые переменные в контракте
*/
pragma solidity ^0.4.16;

import './SpecialManager.sol';

contract Manager is SpecialManager {
	
	// адрес менеджеров
	mapping ( address => bool ) public managerAddressMap;
	// Соответсвие адреса менеджеров и его номера
	mapping ( address => uint256 ) public managerAddressNumberMap;
	// список менеджеров
	mapping ( uint256 => address ) public managerListMap;
	// сколько всего менеджеров
	uint256 public managerCountInt = 0;
	
	// модификатор - если смотрит владелец или менеджер
	modifier isManagerOrOwner {
        require( managerAddressMap[msg.sender]==true || ownerAddressMap[msg.sender]==true );
        _;
    }
	
	// создание/включение менеджера
	function managerOn( address _onManagerAddress ) external isOwner returns (bool retrnVal) {
		// Check if it's a non-zero address
		require( _onManagerAddress != address(0) );
		// если такой менеджер есть
		if ( managerAddressNumberMap[ _onManagerAddress ]>0 )
		{
			// если такой менеджер отключен, влючим его обратно
			if ( !managerAddressMap[ _onManagerAddress ] )
			{
				managerAddressMap[ _onManagerAddress ] = true;
				ContractManagementUpdate( "Manager", msg.sender, _onManagerAddress, true );
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
			managerAddressMap[ _onManagerAddress ] = true;
			managerAddressNumberMap[ _onManagerAddress ] = managerCountInt;
			managerListMap[ managerCountInt ] = _onManagerAddress;
			managerCountInt++;
			ContractManagementUpdate( "Manager", msg.sender, _onManagerAddress, true );
			retrnVal = true;
		}
	}
	
	// отключение менеджера
	function managerOff( address _offManagerAddress ) external isOwner returns (bool retrnVal) {
		// если такой менеджер есть и он не 0-вой, а также активен
		// 0-вой менеджер не может быть отключен
		if ( managerAddressNumberMap[ _offManagerAddress ]>0 && managerAddressMap[ _offManagerAddress ] )
		{
			managerAddressMap[ _offManagerAddress ] = false;
			ContractManagementUpdate( "Manager", msg.sender, _offManagerAddress, false );
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}


	// конструктор, добавляет создателя в менеджеры
	function Manager() public {
		// создаем менеджера
		managerAddressMap[ msg.sender ] = true;
		managerAddressNumberMap[ msg.sender ] = managerCountInt;
		managerListMap[ managerCountInt ] = msg.sender;
		managerCountInt++;
	}
}