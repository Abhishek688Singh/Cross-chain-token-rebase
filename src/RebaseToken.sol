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
    error RebaseToken__InterestRateCannotBeIncreased(
        uint256 newInterestRate,
        uint256 oldInterestRate
    );

    ///////////////////////////////////
    ////     STATE VARIABLES       ////
    ///////////////////////////////////
    uint256 private constant PRECISION_FACTOR = 1e18; //precision factor to avoid rounding errors
    uint256 private s_interestRate = 5e10; //interest rate is 5% in 1e18 format
    //stores the interest rate of each user at the time of deposit.
    mapping(address => uint256) private s_userInterestRate;
    //stores the last updated timestamp of each user.
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    /////////////////////////////////
    ////         EVENTS          ////
    /////////////////////////////////
    event InterestRateDecreased(
        uint256 newInterestRate,
        uint256 oldInterestRate
    );

    /////////////////////////////////
    ////       CONSTRUCTOR       ////
    /////////////////////////////////
    constructor() ERC20("Rebase Sana token", "RST") {}

    ///////////////////////////////////
    ////    EXTERNAL FUNCTIONS     ////
    ///////////////////////////////////

    /**
    @notice this function set the interst rate in the contract.
    @param _newInterestRate the new interest rate to be set in the contract.
    @dev this function reverts if the new interest rate is greater than the old interest rate.
    @dev this function emits an event when the interest rate is decreased.
    */
    function setInterestRate(uint256 _newInterestRate) external {
        //set the interest rate
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCannotBeIncreased(
                _newInterestRate,
                s_interestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterestRateDecreased(_newInterestRate, s_interestRate);
    }

    /**
    @notice this function mints new tokens to the user when they deposit into the vault.
    @param _to the address to mint tokens to.
    @param _amount the amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }
    ///////////////////////////////////
    ////     PUBLIC FUNCTIONS      ////
    ///////////////////////////////////
    /**
    @notice this function calculate and returns the balance of the user including any accrued interest.
    @notice (principal balance) + some interest that has occured since the last time the balance was updated.
    @param _user the address of the user.
    @return the balance of the user including any accrued interest.
     */
    function balanceOf(address _user) public view override returns (uint256) {
        //get the current principal balance of the user (the amount of tokens that have been minted to the user)
        //multiply the principal balance by the interest that has been accumulated since the last time the balance was last updated
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    ///////////////////////////////////
    //       INTERNAL FUNCTIONS      //
    ///////////////////////////////////
    function _mintAccruedInterest(address _user) internal {
        //find the actual balance of the rebase token that has been minted to the user -> principal balance
        //calculate their current balance including any interest -> balanceOf
        //number of tokens that are needed to be minted to the user -> interest = balanceOf - principal balance
        //call the _mint to mint the tokens to the user
        //set the users last updated time stamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256 linearInterest) {
        //we need to calculate the interest that has been accumulated since the last time the balance was updated.
        //this is going to be the linear growth of the interest rate over time.
        //1. calculate the time since last update
        //2. calculate the amount of linear growth
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        linearInterest =
            PRECISION_FACTOR +
            (s_userInterestRate[_user] * timeElapsed);
    }

    ///////////////////////////////////
    //        Getter functions       //
    ///////////////////////////////////
    /**
    @notice this function returns the interest rate of the user at the time of deposit.
    @param _address the address of the user.
    @return the interest rate of the user at the time of deposit.
     */
    function getUserInterestRate(
        address _address
    ) external view returns (uint256) {
        return s_userInterestRate[_address];
    }
}
