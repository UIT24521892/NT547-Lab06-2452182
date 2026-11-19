// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 2452182. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TipJar_2182 {
    address public owner;
    mapping(address => uint256) public stakes;
    uint256 public cooldownEnd;

    event Deposited(address indexed who, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        stakes[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function uiDay() external view returns (uint256) {
        return addmod(block.timestamp / 1 days, 4, 7);
    }

    function collectFees(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "send failed");
    }

    function vestStep() external onlyOwner {
        require(block.timestamp >= cooldownEnd, "locked");
        cooldownEnd = block.timestamp + 1 days;
        (bool ok, ) = payable(owner).call{value: address(this).balance / 10}("");
        require(ok, "release failed");
    }

    function sunset() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function execute(address target, bytes calldata data) external onlyOwner {
        require(target != address(0), "zero");
        require(target.code.length > 0, "not contract");
        (bool ok, ) = target.call(data);
        require(ok, "call failed");
    }

    function updateOwner(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }
}
