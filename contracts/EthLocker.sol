// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EthLocker {
    address public owner;
    uint256 public immutable lockDuration;
    bool public isLinearVesting;

    mapping(address => mapping(address => uint256)) public tokenDeposits;
    mapping(address => mapping(address => uint256)) public vestedAmounts;
    mapping(address => uint256) public ethDeposits;
    mapping(address => uint256) public depositTimes;

    enum VestingStrategy { Immediate, Linear }
    VestingStrategy public vestingStrategy;

    constructor(uint256 _initialLockDuration) {
        owner = msg.sender;
        lockDuration = _initialLockDuration;
        vestingStrategy = VestingStrategy.Immediate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier lockTimePassed() {
        require(block.timestamp >= depositTimes[msg.sender] + lockDuration, "Time has not passed yet");
        _;
    }

    function setVestingStrategy(VestingStrategy _vestingStrategy) external onlyOwner {
        vestingStrategy = _vestingStrategy;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        ethDeposits[msg.sender] += msg.value;
        depositTimes[msg.sender] = block.timestamp;
        vestedAmounts[address(0)][msg.sender] = msg.value; 
    }

    function depositTokens(address token, uint256 amount) public {
        require(amount > 0, "Deposit amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenDeposits[token][msg.sender] += amount;
        depositTimes[msg.sender] = block.timestamp;
        vestedAmounts[token][msg.sender] = amount;
    }

    function withdraw() external lockTimePassed {
        if (vestingStrategy == VestingStrategy.Linear) {
            _withdrawLinearVesting();
        } else {
            _withdrawImmediateVesting();
        }
    }

    function withdrawTokens(address token) external lockTimePassed {
        if (vestingStrategy == VestingStrategy.Linear) {
            _withdrawTokensLinearVesting(token);
        } else {
            _withdrawTokensImmediateVesting(token);
        }
    }

    function _withdrawImmediateVesting() internal {
        uint256 amount = ethDeposits[msg.sender];
        require(amount > 0, "No funds to withdraw");

        ethDeposits[msg.sender] = 0;
        depositTimes[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(msg.sender, amount);
    }

    function _withdrawTokensImmediateVesting(address token) internal {
        uint256 amount = tokenDeposits[token][msg.sender];
        require(amount > 0, "No funds to withdraw");

        tokenDeposits[token][msg.sender] = 0;
        depositTimes[msg.sender] = 0;

        IERC20(token).transfer(msg.sender, amount);

        emit TokenWithdrawal(msg.sender, token, amount);
    }

    function _withdrawLinearVesting() internal {
        uint256 totalAmount = vestedAmounts[address(0)][msg.sender];
        uint256 vestingStartTime = depositTimes[msg.sender];
        uint256 vestingDuration = block.timestamp - vestingStartTime;

        uint256 vestedAmount = (totalAmount * vestingDuration) / lockDuration;
        uint256 amountToWithdraw = vestedAmount - ethDeposits[msg.sender];

        require(amountToWithdraw > 0, "No funds to withdraw");

        ethDeposits[msg.sender] = vestedAmount;

        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(msg.sender, amountToWithdraw);
    }

    function _withdrawTokensLinearVesting(address token) internal {
        uint256 totalAmount = vestedAmounts[token][msg.sender];
        uint256 vestingStartTime = depositTimes[msg.sender];
        uint256 vestingDuration = block.timestamp - vestingStartTime;

        uint256 vestedAmount = (totalAmount * vestingDuration) / lockDuration;
        uint256 amountToWithdraw = vestedAmount - tokenDeposits[token][msg.sender];

        require(amountToWithdraw > 0, "No funds to withdraw");

        tokenDeposits[token][msg.sender] = vestedAmount;

        IERC20(token).transfer(msg.sender, amountToWithdraw);

        emit TokenWithdrawal(msg.sender, token, amountToWithdraw);
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

    event Withdrawal(address indexed user, uint256 amount);
    event TokenWithdrawal(address indexed user, address indexed token, uint256 amount);
}
