pragma solidity ^0.4.24;

/**
* < 헬스메디 토큰 >
* Symbol : HM
* Name : HealthMediToken
* Total Supply : 10,000,000,000.000000000000000000
* 작성일 : 2018.05.31 
* 수정일 : 2018.08.23 
**/


// ERC20(이더리움 네트워크안 데이터전송간 규격) 인터페이스
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// ERC20 구현 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// 사칙연산 오버플로우 방지 라이브러리 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// 기본적인 토큰 기능 구현 컨트랙트 
contract BasicToken is ERC20Basic {
	
  using SafeMath for uint256;
  
  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  //특정 공격을 막기위한 접근제한자 
  modifier onlyPayloadSize(uint size) {
      assert(msg.data.length >= size + 4);
      _;
  }

  /** 
	  desc > 총 발행량 조회
	  return > uint256 : 발행 량
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /** 
	  desc > 토큰 전송 
	  parameter > address _to : 전송 대상 주소 
	  prameter > uint256 _value : 토큰 개수
	  return > bool
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /** 
	  desc > 토큰 전송 
	  parameter > address _to : 전송 대상 주소 
	  prameter > uint256 _value : 토큰 개수
	  return > bool
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// 표준 기능 제공 토큰 컨트랙트 
contract StandardToken is ERC20, BasicToken {

  // 특정 대상에게 토큰 사용권을 주기 위해, approve 내역으로 사용
  mapping (address => mapping (address => uint256)) internal allowed;

	/** 
	  desc > 승인받은 토큰을 특정대상에게 전송함 
	         ex : (B가 주체일때) > A가 B에게 100개의 토큰 사용을 승인한 후, B가 C에게 토큰 전송하려 할때 > _from(A주소), _to(C주소), _value(100)
	  parameter > address _from : 토큰 사용을 승인한 사용자 주소
	  parameter > address _to : 전송 대상 주소 
	  prameter > uint256 _value : 토큰 개수
	  return > bool
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
	/** 
	  desc > 토큰 사용 승인 (특정대상에게 내 토큰 사용권한을 부여함)
	  parameter > address _to : 전송 대상 주소 
	  prameter > uint256 _value : 토큰 개수
	  return > bool
  */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

	/** 
	  desc > 특정대상에게 토큰 사용을 승인해준 것을 반환받
	  parameter > address _owner : 승인해준 토큰 주인 주소 
	  parameter > address _spender : 승인받은 토큰 대상 주소 
	  return > uint256
  */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  // 사용안함 
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  // 사용안함 
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// 발행된 토큰을 태울수 있는 기능을 포함한 컨트랙트(토큰삭제기능)
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

	/** 
	  desc > 토큰 삭제
	  parameter > uint256 삭제할 토큰 개수
  */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

	/** 
	  desc > 토큰 삭제
	  paramter > address _who > 본인 토큰 주소
	  parameter > uint256 삭제할 토큰 개수
  */
  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// 토큰 사용을 특정 대상에게 부여한 경우 승인해준 토큰에 대한 삭제 기능을 포함하는 컨트랙
contract StandardBurnableToken is BurnableToken, StandardToken {

  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

// 접근자의 권한 처리를 위한 컨트랙트 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }
  
  //컨트랙트 생성자만 펑션사용을 할 수 있게 하는 접근제한자
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

	/** 
	  desc > Owner 권한 변경
	  paramter > address newOwner > Owner 권한을 부여할 주소
  */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

	/** 
	  desc > Owner 권한 초기화
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// 토큰 추가발행에 관련된 컨트랙트 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  // 추가발행 flag를 확인하는 접근제한자 
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  /** 
	  desc > 토큰 추가 발행
	  paramter > address _to > 추가 발행시킬 대상 주소
	  paramter > uint256 _amount > 추가 발행할 토큰 개수 
  */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

 /** 
	  desc > 토큰 추가 발행 시작 flag 살림 
  */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


// 보안 관련하여 특정 대상을 블랙리스트에 추가하여 토큰 거래를 할 수 없게 하는 기능을 포함한 컨트랙트 
contract Blacklisted is Ownable {

  mapping(address => bool) public blacklist;

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier notBlacklisted() {
    require(blacklist[msg.sender] == false);
    _;
  }

  /**
   * @dev Adds single address to blacklist.
   * @param _villain Address to be added to the blacklist
   */
  function addToBlacklist(address _villain) external onlyOwner {
    blacklist[_villain] = true;
  }

  /**
   * @dev Adds list of addresses to blacklist. Not overloaded due to limitations with truffle testing.
   * @param _villains Addresses to be added to the blacklist
   */
  function addManyToBlacklist(address[] _villains) external onlyOwner {
    for (uint256 i = 0; i < _villains.length; i++) {
      blacklist[_villains[i]] = true;
    }
  }

  /**
   * @dev Removes single address from blacklist.
   * @param _villain Address to be removed to the blacklist
   */
  function removeFromBlacklist(address _villain) external onlyOwner {
    blacklist[_villain] = false;
  }
}

//헬스메디 토큰 컨트랙트
contract HealthMediToken is Ownable, StandardBurnableToken, MintableToken, Blacklisted {
    
    string public name = "HealthMediToken Test v1";
    string public symbol = "HMT";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 10000000000 * 10 ** uint(decimals);
    
    // 전체 계좌 동결 flag
    bool public isUnlocked = false;
    
    // 생성자 > 총발행량과 생성주소에 총발행량만큼에 토큰 개수를 생성
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
    }
    
    // 전쳬 계좌 동결 여부 접근제한자 
    modifier onlyTransferable() {
        require(isUnlocked);
        _;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transferFrom(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transfer(_to, _value);
    }
    
    // 전체 계좌 동결 해제
    function unlockTransfer() public onlyOwner {
      isUnlocked = true;
    }
    
    // 전체 계좌 동결 
    function lockTransfer() public onlyOwner {
      isUnlocked = false;
    }
}


