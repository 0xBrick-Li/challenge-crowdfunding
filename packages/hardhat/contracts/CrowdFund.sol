// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./FundingRecipient.sol";

contract CrowdFund {
    /////////////////
    /// Errors //////
    /////////////////

    // Errors go here...
    error NotOpenToWithdraw();
    error WithdrawTransferFailed(address to, uint256 amount);
    error TooEarly(uint256 deadline,uint256 currentTimestamp );
    error AlreadyCompleted();

    //////////////////////
    /// State Variables //
    //////////////////////

    mapping(address => uint256) public balances;
    bool public openToWithdraw; // Solidity variables default to an empty/false state
    uint256 public constant thresheld = 1 ether;
    uint256 public deadline = block.timestamp + 30 ;

    FundingRecipient public fundingRecipient;

    ////////////////
    /// Events /////
    ////////////////

    // Events go here...
    event Contribution(address user_address,uint256 fund);

    ///////////////////
    /// Modifiers /////
    ///////////////////

    modifier notCompleted() {
        //确保没有完成
        //如果完成，报错
        if(fundingRecipient.completed()){
            revert AlreadyCompleted();
        }
        _;
    }

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address fundingRecipientAddress) {
        fundingRecipient = FundingRecipient(fundingRecipientAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////
    

    function contribute() public payable  notCompleted{
        balances[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);
     }

    function withdraw() public notCompleted{

        if (openToWithdraw == false){
            revert NotOpenToWithdraw();
        }
        uint256 refund_amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value : refund_amount}("");
        if (success == false){
            revert WithdrawTransferFailed(msg.sender, refund_amount);
        }
        balances[msg.sender] = 0;
        openToWithdraw == false;

    }

    function execute() public notCompleted{
        if (block.timestamp < deadline){
            revert TooEarly(deadline,block.timestamp);
        }
         if(address(this).balance >= thresheld){
            fundingRecipient.complete{value: address(this).balance}();
         }else{
            openToWithdraw = true ;
         }
    }

    receive() external payable {
        contribute();
    }

    ////////////////////////
    /// View Functions /////
    ////////////////////////

    function timeLeft() public view returns (uint256) {
        if(block.timestamp < deadline){
            return deadline - block.timestamp;
        }else{
            return 0;
        }

    }
}
