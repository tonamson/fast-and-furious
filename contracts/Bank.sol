// SPDX-License-Identifier: MIT
/**
 * @notice Mô phỏng lại quá trình rút tiền từ ngân hàng smartcontract blockchain
 * Sử dụng native ETH để có thể exploit reentrancy (ETH transfer trigger receive())
 */
pragma solidity <0.8.0;

contract Bank {
    mapping(address => uint256) public balances;

    // hàm để nhận được token Native mạng lưới
    receive() external payable {}

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // ⚠️ LỖ HỔNG REENTRANCY: Transfer trước, cập nhật balance sau
        // Khi gửi ETH đến contract, sẽ trigger receive() hoặc fallback()
        // Nếu contract đó gọi lại withdraw() trước khi balance được cập nhật,
        // có thể rút nhiều hơn số tiền có (VI PHẠM CEI Pattern)

        // chuyển ETH cho người dùng (TRƯỚC khi cập nhật balance)
        // ⚠️ Đây là điểm trigger reentrancy - ETH transfer sẽ gọi receive() của recipient
        (bool success, ) = msg.sender.call.value(amount)("");
        require(success, "Transfer failed");

        // trừ tiền trong tài khoản của người dùng (SAU khi transfer)
        // ⚠️ Nếu có reentrancy, balance chưa được cập nhật ở đây
        balances[msg.sender] -= amount;
    }

    function getBalance(address account) public view returns (uint256) {
        return balances[account];
    }

    // Helper function để kiểm tra balance của contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
