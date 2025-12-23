// SPDX-License-Identifier: MIT
pragma solidity <0.8.0;

interface IBank {
    function deposit() external payable; // nạp ETH vào bank

    function withdraw(uint256 amount) external; // rút ETH từ bank

    function getBalance(address account) external view returns (uint256); // kiểm tra balance của account

    function getContractBalance() external view returns (uint256); // kiểm tra balance của contract
}
