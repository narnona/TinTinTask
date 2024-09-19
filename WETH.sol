// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 接口规范
interface IERC20 {
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address _owner) external view returns (uint256);
	function transfer(address _to, uint256 _value) external returns (bool);
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
	function approve(address _spender, uint256 _value) external returns (bool);
	function allowance(address _owner, address _spender) external view returns (uint256);
}

contract WETH is IERC20 {
    string public _name = "Wrapped Ether";
	string public _symbol = "WETH";
	uint8  public _decimals = 18;
	
	mapping (address => uint) public _balances;
	mapping (address => mapping (address => uint)) public _allowance;
	
	event Deposit(address _user, uint256 _value);
	event Withdrawal(address _user, uint256 _value);

    // 存款, ETH -> WETH
    function deposit() public payable {
		_balances[msg.sender] += msg.value;
		emit Deposit(msg.sender, msg.value);
	}

    // 提款, WETH -> ETH
    function withdraw(uint256 amount) public {
        require((_balances[msg.sender] - amount) > 0,"Not enough balance.");
        _balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success,"Withdrawal failed");
        emit Withdrawal(msg.sender, amount);
    }

    // IERC20 totalSupply
    function totalSupply() external view override returns (uint256) {
        return address(this).balance;
    }

    // IERC20 balanceOf
    function balanceOf(address _owner) external view override returns (uint256) {
        return _balances[_owner];
    
    }
    
    // IERC20 transfer
    function transfer(address _to, uint256 _value) external override returns (bool) {
        require(_balances[msg.sender] > _value,"Not enough balance.");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true ;
     }

    // IERC20 transferFrom
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        require(_balances[_from] >=_value,"Not enough balance.");
        require((_allowance[_from][msg.sender] -_value) >0,"Not enough balance.");
        
        _allowance[_from][msg.sender] -=_value;
        _balances[_from] -=_value;
        _balances[_to] +=_value;
        emit Transfer(_from,_to,_value);
        return true;
    }

     // IERC20 approve
    function approve(address _spender, uint256 _value) external override returns (bool) {
         _allowance[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
         return true ;
    }

    // IERC20 allowance
    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return _allowance[_owner][_spender];
    }
}
