// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
@title RebaseToken
@author Abhishek Singh
@notice this is a cross-chain rebase token that incentivises user to deposited into a vault and gain interest on their deposits. The token supply is elastic and can be rebased to increase or decrease the total supply of the token.
 @notice the rate of interest in the smartcontrct can only be decreased.
 @notice each user will have their own interest rate that is decided at the time of deposit.
 */
contract RebaseToken is ERC20 {
    /////////////////////////////////
    ////         ERRORS          ////
    /////////////////////////////////
    error RebaseToken__InterestRateCannotBeIncreased(uint256 newInterestRate, uint256 oldInterestRate);

    ///////////////////////////////////
    ////     STATE VARIABLES       ////
    ///////////////////////////////////
    uint256 private s_interestRate;
    //stores the interest rate of each user at the time of deposit.
    mapping(address => uint256) private s_userInterestRate;

    /////////////////////////////////
    ////         EVENTS          ////
    /////////////////////////////////
    event InterestRateDecreased(uint256 newInterestRate, uint256 oldInterestRate);

    /////////////////////////////////
    ////       CONSTRUCTOR       ////
    /////////////////////////////////
    constructor() ERC20("Rebase Sana token", "RST") {}

    ///////////////////////////////////
    ////    EXTERNAL FUNCTIONS     ////
    ///////////////////////////////////

    /*
    @notice this function set the interst rate in the contract.
    @params _newInterestRate the new interest rate to be set in the contract.
    @dev this function reverts if the new interest rate is greater than the old interest rate.
    @dev this function emits an event when the interest rate is decreased.
    */
    function setInterestRate(uint256 _newInterestRate) external {
        //set the interest rate
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCannotBeIncreased(_newInterestRate, s_interestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateDecreased(_newInterestRate, s_interestRate);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    ///////////////////////////////////
    //        Getter functions       //
    ///////////////////////////////////
    function getInterestRate(address _address) external view returns (uint256) {
        return s_userInterestRate[_address];
    }
}
