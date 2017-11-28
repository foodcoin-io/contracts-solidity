/*
	Управление владельцами контракта
	Владелец может останавливать или возобновлять эмиссию, устанавливать потолок эмиссии, разрешать обмен токенами, выполнять функции менеджра и специального менеджера
*/
pragma solidity ^0.4.16;

contract Owner {
	
	// Адреса владельцев
	mapping ( address => bool ) public ownerAddressMap;
	// Соответсвие адреса владельца и его номера
	mapping ( address => uint256 ) public ownerAddressNumberMap;
	// список менеджеров
	mapping ( uint256 => address ) public ownerListMap;
	// сколько всего менеджеров
	uint256 public ownerCountInt = 0;
	
	// событие "изменение в контракте"
	event ContractManagementUpdate( string _type, address _initiator, address _to, bool _newvalue );

	// модификатор - если смотрит владелец
	modifier isOwner {
        require( ownerAddressMap[msg.sender]==true );
        _;
    }
	
	// создание/включение владельца
	function ownerOn( address _onOwnerAddress ) external isOwner returns (bool retrnVal) {
		// Check if it's a non-zero address
		require( _onOwnerAddress != address(0) );
		// если такой владелец есть (стартового владельца удалить нельзя)
		if ( ownerAddressNumberMap[ _onOwnerAddress ]>0 )
		{
			// если такой владелец отключен, влючим его обратно
			if ( !ownerAddressMap[ _onOwnerAddress ] )
			{
				ownerAddressMap[ _onOwnerAddress ] = true;
				ContractManagementUpdate( "Owner", msg.sender, _onOwnerAddress, true );
				retrnVal = true;
			}
			else
			{
				retrnVal = false;
			}
		}
		// если такого владеьца нет
		else
		{
			ownerAddressMap[ _onOwnerAddress ] = true;
			ownerAddressNumberMap[ _onOwnerAddress ] = ownerCountInt;
			ownerListMap[ ownerCountInt ] = _onOwnerAddress;
			ownerCountInt++;
			ContractManagementUpdate( "Owner", msg.sender, _onOwnerAddress, true );
			retrnVal = true;
		}
	}
	
	// отключение менеджера
	function ownerOff( address _offOwnerAddress ) external isOwner returns (bool retrnVal) {
		// если такой менеджер есть и он не 0-вой, а также активен
		// 0-вой менеджер не может быть отключен
		if ( ownerAddressNumberMap[ _offOwnerAddress ]>0 && ownerAddressMap[ _offOwnerAddress ] )
		{
			ownerAddressMap[ _offOwnerAddress ] = false;
			ContractManagementUpdate( "Owner", msg.sender, _offOwnerAddress, false );
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}

	// конструктор, при создании контракта добалвяет создателя в "неудаляемые" создатели
	function Owner() public {
		// создаем владельца
		ownerAddressMap[ msg.sender ] = true;
		ownerAddressNumberMap[ msg.sender ] = ownerCountInt;
		ownerListMap[ ownerCountInt ] = msg.sender;
		ownerCountInt++;
	}
}