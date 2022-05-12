// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interfaces/IERC20.sol"
import "./libraries/SafeMath.sol"
import "./Ownable.sol"

contract Sale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  IERC20 public token;

  // Address where funds are collected
  address payable public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  uint256 public _startTime;
  uint256 public _endTime;

  mapping (address => uint256) tokenHolders;
  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );


  constructor(uint256 _rate, address payable _wallet, IERC20 _token) {
    require(_rate > 0);
    require(_wallet != address(0));


    rate = _rate;
    wallet = _wallet;
    token = _token;
    // _startTime = startTime;
    // _endTime = endTime;
  }

  fallback () external payable {
    buyTokens(msg.sender);
  }

  receive () external payable {
      buyTokens(msg.sender);
  }

  // modifier hasStarted()
  // {
  //     require(block.timestamp > _startTime, "Presale has not started yet");
  //     _;
  // }
  //
  // modifier hasEnded()
  // {
  //     require(block.timestamp < _endTime, "Presale has already finished");
  //     _;
  // }

  modifier hasTokens()
  {
      require (token.balanceOf(address(this)) > 0 , "No tokens left");
      _;
  }

  // modifier isVestingFinished()
  // {
  //     require(block.timestamp > 1622530800, "Vesting period is over");
  //     _;    //vesting periods ends at 01-06-2021 12:00 pm
  //
  // }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    uint256 _50Percent = tokens.div(2);
    tokenHolders[_beneficiary] = _50Percent;
    // update state
    weiRaised = weiRaised.add(weiAmount);

    _deliverTokens(_beneficiary, _50Percent);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      _50Percent
    );


    _forwardFunds();
  }


  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    view internal hasTokens
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }


  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }


  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function withdraw (address withdrawer) public
  {
      require(isFinalized)
      require(withdrawer != address(0), "Transfer to zero address");
      uint256 withdrawnAmount = tokenHolders[withdrawer];
      _deliverTokens(withdrawer, withdrawnAmount);
  }
  function sendTokensBack() public onlyOwner
  {
     token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));

  }
}
