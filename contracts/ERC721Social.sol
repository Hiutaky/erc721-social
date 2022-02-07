// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
 *   @dev ERC721Social assign ipfs-based profiles to all the tokens ID related to a specific ERC721 Contract
 *    Accept payments in Governance Token and ERC20 Tokens
 *    Author: Alessandro De Cristofaro
 */
 
contract ERC721Social {
    using SafeMath for uint;

    address public owner;
    mapping (uint => string) public profileHashes;

    IERC20 public Token;
    IERC721 public NFTCollection;

    uint private tokenCost = 200 * 1e18;
    uint private governanceCost = 50 * 1e18;

    modifier isOwner() {
        require(
            owner == msg.sender,
            "ERR_NOT_OWNER"
        );
        _;
    }

    modifier isApprovedGovernance( ) {
        require( 
            _getcostInGovernance() == msg.value,
            "ERR_INSUFFICIENT_GOVERNANCE" 
        );
        _;
    }

    modifier isApprovedGrave( ) {
        require( 
            _getCostInGrave() <= Token.allowance( msg.sender, address(this) ),
            "ERR_INCREASE_TOKEN_ALLOWANCE"
        );
        _;
    }

    modifier isTokenOwner( uint tokenId ) {
        require( 
            NFTCollection.ownerOf( tokenId ) == msg.sender,
            "ERR_NOT_OWNER_OF_TOKEN"
        );
        _;
    }

    event DescriptionUpdate( address ownerOf, uint indexed tokenId, string ipfsHash, uint timestamp );

    constructor ( ) {
        owner = msg.sender;
    }

    /** 
        public functions
    */
    function updateUsingGovernance( uint tokenId, string memory ipfsHash ) public payable isTokenOwner( tokenId ) isApprovedGovernance( ) {
        _updateSkullDescription( msg.sender, tokenId, ipfsHash );
    }

    function updateUsingGrave( uint tokenId, string memory ipfsHash ) public isTokenOwner( tokenId ) isApprovedGrave( ) {
        require( 
            Token.transferFrom( msg.sender, address(this), _getCostInGrave() ),
            "ERR_GRAVE_PAYMENT_FAILED"
        );
        _updateSkullDescription( msg.sender, tokenId, ipfsHash );
    }

    function _getCostInGrave() public view returns( uint ) {
        return tokenCost;
    }

    function _getcostInGovernance() public view returns(uint) {
        return governanceCost;
    }

    /**
        admin functions
    */
    
    function AdminUpdateDescription( address ownerOf, uint tokenId, string memory ipfsHash ) public isOwner() {
        _updateSkullDescription( ownerOf, tokenId, ipfsHash );
    }

    function AdminUpdateCost( uint _governanceCost, uint _tokenCost ) public isOwner() {
        if( governanceCost > 0 ){
            governanceCost = _governanceCost;
        }

        if( tokenCost > 0 ){
            tokenCost = _tokenCost;
        }
    }

    function AdminSetContracts( IERC20 tokenContract, IERC721 nftContract ) public isOwner() {
        if( IERC20(address(0)) != tokenContract ){
            Token = tokenContract;
        }

        if( IERC721(address(0)) != nftContract ){
            NFTCollection = nftContract;
        }
    }

    function AdminWithdraw( address payable _reciever ) public isOwner() {
        AdminWithdrawGovernance( _reciever );
        AdminWithdrawToken( _reciever );
    }

    function AdminWithdrawGovernance( address payable _reciever ) public isOwner() {
        uint balance = address(this).balance;
        if( balance > 0 ) {
            (bool sent, ) = _reciever.call{value: balance }("");
            require(sent, "ERR_FAILED_TO_SEND_GOVERNANCE");
        }
    }

    function AdminWithdrawToken( address _reciever ) public isOwner() {
        uint balance = Token.balanceOf( address( this ) );
        if( balance > 0 ){
            require( Token.transferFrom( 
                address(this), 
                _reciever,
                balance
            ), "ERR_FAILED_TO_SEND_TOKEN");
        }
    }

    /** 
        internal functions
    */

    function _updateSkullDescription( address sender, uint tokenId, string memory ipfsHash ) internal {
        profileHashes[tokenId] = ipfsHash;
        emit DescriptionUpdate( sender, tokenId, ipfsHash, block.timestamp );
    }
}