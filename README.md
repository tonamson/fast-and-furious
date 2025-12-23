# Reentrancy Attack Demo - Fast and Furious

Dự án mô phỏng **Reentrancy Attack** trên smart contract blockchain, khai thác lỗ hổng **CEI Pattern** (Checks-Effects-Interactions) trong contract Bank.

## 📋 Tổng quan

Dự án này bao gồm:

- **Bank.sol**: Contract ngân hàng có lỗ hổng reentrancy (vi phạm CEI Pattern)
- **Exploit.sol**: Contract khai thác lỗ hổng để rút tiền nhiều lần
- **Test cases**: Mô phỏng quá trình exploit bằng TypeScript/Mocha

## 🔍 Reentrancy Attack là gì?

**Reentrancy Attack** là một lỗ hổng bảo mật phổ biến trong smart contract, xảy ra khi:

1. Contract A gọi function của Contract B
2. Contract B gọi lại function của Contract A (trước khi A hoàn thành xử lý)
3. Contract A chưa cập nhật state → B có thể khai thác state cũ

### Ví dụ trong dự án này:

```
1. Exploit gọi Bank.withdraw(1 ETH)
2. Bank transfer 1 ETH → trigger Exploit.receive()
3. Exploit.receive() lại gọi Bank.withdraw(1 ETH) (reentrancy!)
4. Bank chưa trừ balance → vẫn pass require(balance >= 1 ETH)
5. Bank transfer thêm 1 ETH → loop tiếp tục...
```

## ⚠️ Lỗ hổng trong Bank Contract

### Code có lỗ hổng:

```solidity
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // ❌ SAI: Transfer TRƯỚC, cập nhật balance SAU
    (bool success, ) = msg.sender.call.value(amount)("");
    require(success, "Transfer failed");

    // ⚠️ Nếu có reentrancy, dòng này chưa chạy → balance chưa bị trừ
    balances[msg.sender] -= amount;
}
```

### Vấn đề:

- **Vi phạm CEI Pattern**: Transfer (Interaction) trước khi cập nhật balance (Effect)
- Khi ETH transfer trigger `receive()` của recipient, balance vẫn chưa bị trừ
- Attacker có thể rút nhiều lần với cùng một balance

### ⚠️ Lưu ý về Solidity Version:

**Lỗ hổng này chỉ xảy ra ở Solidity < 0.8.0:**

- **Solidity < 0.8.0**: Không có built-in protection, dễ bị exploit như trong demo này
- **Solidity >= 0.8.0**: Đã có một số cải thiện về overflow/underflow protection, nhưng **vẫn không đủ** để chống reentrancy attack

**Khuyến nghị bảo mật:**

Dù đã dùng Solidity 0.8.0+, bạn **vẫn phải** sử dụng `ReentrancyGuard` cho các hàm quan trọng về xử lý tiền bạc để tránh call loop:

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Bank is ReentrancyGuard {
    function withdraw(uint256 amount) public nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount; // Cập nhật state trước
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**Lý do:**

- Solidity 0.8.0+ chỉ bảo vệ khỏi arithmetic overflow/underflow
- **KHÔNG** tự động bảo vệ khỏi reentrancy attack
- `ReentrancyGuard` là giải pháp chuẩn để ngăn chặn call loop trong các hàm xử lý tiền

## 🎯 Cách Exploit hoạt động

### Exploit Contract:

```solidity
receive() external payable {
    // Chỉ attack khi ETH đến từ Bank
    if (msg.sender == address(bank) && attackCount < maxAttacks) {
        attackCount++;
        bank.withdraw(msg.value); // Reentrancy!
    }
}
```

### Flow Attack:

```
1. Exploit deposit 1 ETH vào Bank
   → balance[Exploit] = 1 ETH

2. Exploit gọi withdraw(1 ETH)
   → Bank transfer 1 ETH → trigger receive()
   → receive() gọi lại withdraw(1 ETH) (reentrancy!)
   → Bank transfer thêm 1 ETH → trigger receive() lần 2
   → ... (loop cho đến khi maxAttacks hoặc Bank hết ETH)

3. Kết quả: Rút được nhiều ETH hơn số đã deposit!
```

## 🚀 Cài đặt và Chạy

### Yêu cầu:

- Node.js >= 18
- Yarn hoặc npm

### Cài đặt dependencies:

```bash
yarn install
# hoặc
npm install
```

### Chạy tests:

```bash
# Chạy tất cả tests
npx hardhat test

# Chạy test exploit
npx hardhat test test/Attack.ts
```

### Kết quả mong đợi:

```
Test: Exploit
  ✓ Số tiền nạp: 1.0
  ✓ Số tiền exploit rút: 0.0 (đã rút hết!)
  ✓ Bank contract balance giảm (bị exploit)
```
