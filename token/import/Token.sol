/*
	Прототип токен контракта
*/
contract Token {
	// общее кол-во токенов наданный момент
	uint256 public totalSupply;
	// потолок на кол-во токенов
	uint256 public tokenCreationCap = 0;
	// сколько токенов на конкретном адресе
	function balanceOf(address _owner) constant returns (uint256 balance);
	// перевод токенов с адреса "вуызвавшего контракт" на указанный адрес
	function transfer(address _to, uint256 _value) returns (bool success);
	// перевод токенов с адреса на адрес (механизм переводов для делегированных счетов)
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
	// выделение делегирования на управление счета
	function approve(address _spender, uint256 _value) returns (bool success);
	// показывает, сколько один счет может снимать средств с другого счета
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);
	// событие "перевод токенов"
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	// событие "делегирование средств", для функции approve()
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}