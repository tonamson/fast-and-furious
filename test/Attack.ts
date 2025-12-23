import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("Attack", function () {
  async function deployContract() {
    const [user0, user1] = await ethers.getSigners();
    const Bank = await ethers.deployContract("Bank");
    const Exploit = await ethers.deployContract("Exploit", [
      await Bank.getAddress(),
    ]);

    // nạp 10 ETH cho contract bank để test exploit
    await user1.sendTransaction({
      to: await Bank.getAddress(),
      value: ethers.parseEther("10"),
    });

    // nạp 10 ETH cho contract exploit để test exploit
    await user1.sendTransaction({
      to: await Exploit.getAddress(),
      value: ethers.parseEther("10"),
    });

    return { Bank, Exploit };
  }

  it("Test: Thao tác bình thường của user", async function () {
    const [user0] = await ethers.getSigners();
    const { Bank } = await deployContract();

    // tiến hành nạp 1 ETH vào bank
    await Bank.deposit({
      value: ethers.parseEther("1"),
    });

    // user có 1 ETH trong bank
    expect(await Bank.getBalance(user0.address)).to.be.equal(
      ethers.parseEther("1")
    );

    // kiểm tra eth trong bank
    expect(await Bank.getContractBalance()).to.be.equal(
      ethers.parseEther("11")
    );
  });

  it("Test: Exploit", async function () {
    const [user0] = await ethers.getSigners();
    const { Bank, Exploit } = await deployContract();

    console.log("--------------------------------");
    // tiến hành gọi exploit nạp tiền vào bank
    await Exploit.depositToBank({
      value: ethers.parseEther("1"),
    });

    console.log(
      "Số tiền bank ban đầu:",
      ethers.formatEther(await Bank.getContractBalance())
    );

    // kiểm tra balance của exploit
    const currentDeposit = await Bank.getBalance(await Exploit.getAddress());
    expect(currentDeposit).to.be.equal(ethers.parseEther("1"));
    console.log("Số tiền attacker nạp:", ethers.formatEther(currentDeposit));

    // exploit rút tiền từ bank
    try {
      await Exploit.withdrawFromBank(ethers.parseEther("1"));
    } catch (error) {
      console.log(error);
    }

    console.log(
      "Số tiền bank còn lại:",
      ethers.formatEther(await Bank.getContractBalance())
    );
  });
});
