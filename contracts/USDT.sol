// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, Ownable {
    constructor(address initialOwner) ERC20("USDT", "USDT") public {
        _mint(initialOwner, 10 * 10 ** 18); // lúc tạo contract USDT sẽ có 10 USDT cho người tạo trước
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
