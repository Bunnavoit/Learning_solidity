// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract EthLocker {
    address public owner;
    uint256 public immutable lockDuration;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public depositTimes;

    constructor() {
        owner = msg.sender;
        lockDuration = 40;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier lockTimePassed() {
        require(block.timestamp >= depositTimes[msg.sender] + lockDuration, "time has not passed yet");
        _;
    }

    function setLockDuration(uint256 _lockDuration) external onlyOwner {
        lockDuration = _lockDuration;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        deposits[msg.sender] += msg.value;
        depositTimes[msg.sender] = block.timestamp;
    }

    function withdraw() external lockTimePassed {
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "No funds to withdraw");

        deposits[msg.sender] = 0;
        depositTimes[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getRemainingLockTime(address user) external view returns (uint256) {
        if (block.timestamp >= depositTimes[user] + lockDuration) {
            return 0;
        } else {
            return (depositTimes[user] + lockDuration) - block.timestamp;
        }
    }

    receive() external payable {
        deposit();
    }
}
