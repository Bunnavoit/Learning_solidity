// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EthLocker {
    address public owner;
    uint256 public immutable lockDuration; 
    mapping(address => uint256) public ethDeposits;
    mapping(address => uint256) public depositTimes;

    mapping(address => mapping(address => uint256)) public tokenDeposits;

    constructor(uint256 _initialLockDuration) {
        owner = msg.sender;
        lockDuration = _initialLockDuration;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier lockTimePassed() {
        require(block.timestamp >= depositTimes[msg.sender] + lockDuration, "Time has not passed yet");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        ethDeposits[msg.sender] += msg.value;
        depositTimes[msg.sender] = block.timestamp;
    }

    function depositTokens(address token, uint256 amount) public {
        require(amount > 0, "Deposit amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenDeposits[token][msg.sender] += amount;
        depositTimes[msg.sender] = block.timestamp;
    }

    function withdraw() external lockTimePassed {
        uint256 amount = ethDeposits[msg.sender];
        require(amount > 0, "No funds to withdraw");

        ethDeposits[msg.sender] = 0;
        depositTimes[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function withdrawTokens(address token) external lockTimePassed {
        uint256 amount = tokenDeposits[token][msg.sender];
        require(amount > 0, "No funds to withdraw");

        tokenDeposits[token][msg.sender] = 0;
        depositTimes[msg.sender] = 0;

        IERC20(token).transfer(msg.sender, amount);
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
