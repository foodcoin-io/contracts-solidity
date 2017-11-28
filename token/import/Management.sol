/*
	Управление статусами контракта
	Наследует контракту manager.sol
*/
pragma solidity ^0.4.16;

import './Manager.sol';

contract Management is Manager {
	
	// текстовое описание контракта
	string public description = "";
	
	// текущий статус разрешения транзакций
	// TRUE - транзакции возможны
	// FALSE - транзакции не возможны
	bool public transactionsOn = false;
	
	// текущий статус эмиссии
	// TRUE - эмиссия возможна, менеджеры могут добавлять в контракт токены
	// FALSE - эмиссия невозможна, менеджеры не могут добавлять в контракт токены
	bool public emissionOn = true;

	// потолок эмиссии
	uint256 public tokenCreationCap = 0;
	
	// модификатор - транзакции возможны
	modifier isTransactionsOn{
        require( transactionsOn );
        _;
    }
	
	// модификатор - эмиссия возможна
	modifier isEmissionOn{
        require( emissionOn );
        _;
    }
	
	// функция изменения статуса транзакций
	function transactionsStatusUpdate( bool _on ) external isOwner
	{
		transactionsOn = _on;
	}
	
	// функция изменения статуса эмиссии
	function emissionStatusUpdate( bool _on ) external isOwner
	{
		emissionOn = _on;
	}
	
	// установка потолка эмиссии
	function tokenCreationCapUpdate( uint256 _newVal ) external isOwner
	{
		tokenCreationCap = _newVal;
	}
	
	// событие, "смена описания"
	event DescriptionPublished( string _description, address _initiator);
	
	// изменение текста
	function descriptionUpdate( string _newVal ) external isOwner
	{
		description = _newVal;
		DescriptionPublished( _newVal, msg.sender );
	}
}