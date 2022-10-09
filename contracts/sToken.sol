pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract sToken is ERC20, ERC20Burnable, Ownable {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}