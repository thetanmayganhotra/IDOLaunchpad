pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract sToken is ERC20, ERC20Burnable, Ownable {
mapping(address => uint256) Nooftickets;
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
  function AddNoOfTickets(address _user, uint256 tickets) external {
        Nooftickets[_user]+= tickets;
  }

  function removeNoOfTickets(address _user, uint256 tickets) external {
        Nooftickets[_user]-= tickets;
  }
  function GetNoOfTickets(address _user) external returns(uint256){
        uint256 tickets;
        tickets = Nooftickets[_user];
        return tickets;
  }
}