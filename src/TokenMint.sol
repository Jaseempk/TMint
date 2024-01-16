// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
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
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Error
error TMint__PresaleInactive();
error TMint__PublicsaleInactive();
error TMint__ContributionOuttaLimit();
error TMint__CapExceeded();
error TMint__PublicsaleActive();
error TMint__PresaleActive();
error TMint__SaleOngoing();
error TMint__MCapTooLow();
error TMint__CallerIsSus();
error TMint__InsufficientBalance();

contract TMint is ERC20,Ownable {

    // Token contract reference
    //ERC20 public token;

    //Sale parameters
    //uint256 public s_tokenCounter;

    // Presale parameters
    uint256 public immutable i_presaleCap;
    uint256 public immutable i_presaleMinPurchase; 
    uint256 public immutable i_presaleMaxPurchase;

    // Public sale parameters  
    uint256 public publicSaleCap;
    uint256 public publicSaleMinPurchase;
    uint256 public publicSaleMaxPurchase;

    // Presale state
    bool public isPresaleActive;
    uint256 public presaleRaisedAmount;

    // Public sale state    
    bool public isPublicSaleActive; 
    uint256 public publicSaleRaisedAmount;

    //mapping
    mapping(address => uint256)public etherDepositted;
    mapping(uint256 => address)public counterToAddress;

    // Events
    event PresaleContribution(address indexed contributor, uint256 amount,uint256 tokensAllocated);
    event PublicSaleContribution(address indexed contributor, uint256 amount,uint256 _tokenAllocated);
    event TokensWithdrawn(address indexed receiver, uint256 amount);

    /**
     * @dev Contract constructor
     * @param _presaleCap Presale cap in wei
     * @param _publicSaleCap Public sale cap in wei
     * @param _presaleMinPresale minimum contribution in presale in wei 
     * @param _presaleMaxPresale maximum contribution in presale in wei
     * @param _publicSaleMin Public sale minimum contribution in wei
     * @param _publicSaleMax Public sale maximum contribution in wei
     */
    constructor(
        //address _tokenAddress,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _presaleMinPresale,
        uint256 _presaleMaxPresale,
        uint256 _publicSaleMin, 
        uint256 _publicSaleMax
    ) Ownable(msg.sender)ERC20("TMint","TMT"){
        require(_presaleCap > 0, "Presale cap should be > 0");
        require(_publicSaleCap > 0, "Public sale cap should be > 0");

        //token = ERC20(_tokenAddress);
        publicSaleCap = _publicSaleCap;
        i_presaleCap = _presaleCap; 
        i_presaleMinPurchase = _presaleMinPresale;
        i_presaleMaxPurchase = _presaleMaxPresale;  
        publicSaleMinPurchase = _publicSaleMin;
        publicSaleMaxPurchase = _publicSaleMax;


        // Presale is active by default 
        isPresaleActive = true;
    }

    /**
     * @dev Contribute ETH to presale
     */
    function contributeToPresale() public payable  {
        if(!isPresaleActive) revert TMint__PresaleInactive();
        if(!(msg.value >= i_presaleMinPurchase && msg.value <= i_presaleMaxPurchase)) revert TMint__ContributionOuttaLimit();
        if(!(presaleRaisedAmount + msg.value <= i_presaleCap)) revert TMint__CapExceeded();

        etherDepositted[msg.sender]+=msg.value;

        // Update presale amount
        presaleRaisedAmount += msg.value;

        // Mint tokens to contributor
        uint256 tokensToMint = (msg.value) / (0.00000001 ether); // At 1 token = 0.00000001 ETH rate 
        _mint(msg.sender,tokensToMint);
        //token._mint(msg.sender, tokensToMint);


        emit PresaleContribution(msg.sender, msg.value,tokensToMint);
    }

    /**
     * @dev Start public sale
     */  
    function startPublicSale() public onlyOwner {
        if(isPresaleActive) revert TMint__PresaleActive();
        if(isPublicSaleActive)revert TMint__PublicsaleActive();

        isPublicSaleActive = true;
    }

    /**
     * @dev Contribute ETH to public sale
     */
    function contributeToPublicSale() public payable  {
        if(!isPublicSaleActive) revert TMint__PublicsaleInactive();
        if(!(msg.value >= publicSaleMinPurchase && msg.value <= publicSaleMaxPurchase))revert TMint__ContributionOuttaLimit();
        if(!(publicSaleRaisedAmount + msg.value <= publicSaleCap))revert TMint__CapExceeded();

        etherDepositted[msg.sender]+=msg.value;


        publicSaleRaisedAmount += msg.value;

        uint256 tokensToMint = (msg.value ) / (0.0000001 ether);
        _mint(msg.sender, tokensToMint);
        //token.mint(msg.sender, tokensToMint);

        emit PublicSaleContribution(msg.sender, msg.value,tokensToMint);
    }

    /**
     * @dev Owner can withdraw tokens to specified address
     */
    function withdrawTokens(address _receiver, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount should be > 0");

        transfer(_receiver, _amount);
        //token.transfer(_receiver, _amount);

        emit TokensWithdrawn(_receiver, _amount);
    }

    /**
     * @dev Refund user if minimum contribution is not reached
     */
    function getRefund() public {
        if(isPublicSaleActive && isPresaleActive)revert TMint__SaleOngoing();
        if(!((i_presaleCap > 0 && presaleRaisedAmount < i_presaleCap) || (publicSaleCap > 0 && publicSaleRaisedAmount < publicSaleCap))) revert TMint__MCapTooLow();
        if(!(etherDepositted[msg.sender]>0)) revert TMint__CallerIsSus();

        uint256 contributeAmount = etherDepositted[msg.sender];
        etherDepositted[msg.sender]=0;
        payable(msg.sender).transfer(contributeAmount);
    }

    /**
     * @dev Owner can withdraw ETH
     */
    function withdrawETH() public onlyOwner {
        if(address(this).balance<=0) revert TMint__InsufficientBalance();
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
    receive()external payable{}
}