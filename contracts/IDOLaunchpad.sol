pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDO.sol";
import "./IPool.sol";
import "./Whitelist.sol";
import "./Pool.sol";

contract IDOLaunchPad is Ownable, IDO{

    using SafeMath for uint256;
    IERC20 public sToken;
    IERC20 public projectToken;
    uint256 public totalUniqueStakers;
    uint256 public minStake;
    uint256[2] public plans = [15 days , 90 days];
    mapping(address => uint256) IDOtimestamps;

    mapping(uint => address) IDOs;
    uint256 idocount;
    address currentIDO;
    address current15daypool;
    address current90daypool;



    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 plan;
        bool withdrawan;
        bool unstaked;
        address poolAddress;
    }

    struct User{
        uint256 totalstakeduser;
        uint256 stakecount;
        uint256 claimedstakeTokens;
        uint256 unStakedTokens;
        mapping(uint256 => Stake) stakerecord;
        mapping(uint256 => address) poolAddresses;
        uint256 tickets;
        uint256 NoOfIDOs;
    }

     mapping(address => User) public users;
     mapping(address => bool) public uniqueStaker;
  

    constructor(address _sToken , address _projectToken) {
    sToken = IERC20(_sToken);
    projectToken = IERC20(_projectToken);
     minStake = 500;
     idocount = 0;
     current90daypool == address(0);
  }


  event Staked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event UnStaked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event UNIQUESTAKERS(address indexed _user);


    function stake(uint256 amount, uint256 plan) public {
      
      address newpool;
        require(plan >= 0 && plan < 2, "put valid plan details");
        require(
            amount >= minStake,
            "cant deposit need to stake more than minimum amount"
        );
        if (!uniqueStaker[msg.sender]) {
            uniqueStaker[msg.sender] = true;
            totalUniqueStakers++;
            emit UNIQUESTAKERS(msg.sender);
        }


      
       
        User storage user = users[msg.sender];
        user.stakecount++;
        if (plan == 0) {
          user.poolAddresses[user.stakecount] = current15daypool;
          IPool loadpool = IPool(user.poolAddresses[user.stakecount]);
          loadpool.updatePoolStatus(2);
          loadpool.deposit{value: amount}(msg.sender);
          uint ticketcount = ONE*(amount/minStake);
          sToken.AddNoOfTickets(msg.sender,ticketcount);
          
          user.tickets += ticketcount;
          
          
          }

        else {
          if (current90daypool == address(0)){
          uint256 currenttimestamp = block.timestamp;
          uint256 end = block.timestamp.add(7776000);
          current90daypool = createPool(ONE,minStake,currenttimestamp,end,0);
          }
          user.poolAddresses[user.stakecount] = current90daypool;
          IPool loadpool = IPool(user.poolAddresses[user.stakecount]);
          loadpool.updatePoolStatus(2);
          loadpool.deposit(msg.sender);
          user.tickets += ((12*ONE*amount)/(10*minStake));
          require(amount <= sToken.balanceOf(msg.sender), "you don't have enough balance.");
          sToken.transferFrom(msg.sender , user.poolAddresses[user.stakecount] , amount);

          }

        sToken.transferFrom(msg.sender, owner, amount);
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(plans[plan]);
        
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function createIDO(address _walletAddress, address _projectTokenAddress,uint16 _minAllocationPerUser,uint256 _maxAllocationPerUser,uint256 _totalTokenProvided,uint256 _exchangeRate,uint256 _tokenPrice,uint256 _totalTokenSold) onlyOwner public{
        IDO newIDO = new IDO();
        IDOs[idocount] = newIDO ; 
        idocount++;
        newIDO.addIDOInfo(_walletAddress,_projectTokenAddress,_minAllocationPerUser,_maxAllocationPerUser,_totalTokenProvided,_exchangeRate,_tokenPrice,_totalTokenSold);
        current15daypool = newIDO.createPool(ONE,minStake,block.timestamp,(block.timestamp + 15 days), 0);
        current15daypool.updatePoolStatus(2);
        IDOtimestamps[newIDO] = block.timestamp;


    }

    function unstake(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );

        require((block.timestamp - user.stakerecord[count].stakeTime) > plans[user.stakerecord[count].plan],"You cant unstake sooner than you planned") ;
        uint stakeamount = user.stakerecord[count].amount;
        IPool loadpool = IPool(user.poolAddresses[count]);
        loadpool.

        user.unStakedTokens += user.stakerecord[count].amount;
        user.stakerecord[count].unstaked = true;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }
    
    
    function stakedetails(address add, uint256 count)
        public
        view
        returns (
        uint256 stakeTime,
        uint256 withdrawTime,
        uint256 amount,
        uint256 bonus,
        uint256 plan,
        bool withdrawan,
        bool unstaked
        )
    {
        return (
            users[add].stakerecord[count].stakeTime,
            users[add].stakerecord[count].withdrawTime,
            users[add].stakerecord[count].amount,
            users[add].stakerecord[count].bonus,
            users[add].stakerecord[count].plan,
            users[add].stakerecord[count].withdrawan,
            users[add].stakerecord[count].unstaked
        );
    }

    function calculateTicketRewards(uint256 amount, uint256 plan)
        external
        view
        returns (uint256)
    { address counttickets;
         if (plan == 0) {
         
          counttickets = ONE*(amount/minStake);

          }

        else {

          counttickets = ((12*ONE*amount)/(10*minStake));

          }

      return counttickets;
    }

    function currentStaked(address add) external view returns (uint256) {
        uint256 currentstaked;
        for (uint256 i; i < users[add].stakecount; i++) {
            if (!users[add].stakerecord[i].withdrawan) {
                currentstaked += users[add].stakerecord[i].amount;
            }
        }
        return currentstaked;
    }



}

//library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }


}