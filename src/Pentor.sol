// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC20.sol";

contract Pentor is ERC721TokenReceiver {

    struct SwapDetails {
        address collectionAddress;
        address tokenOwner;
        uint256 tokenId;
        uint8 createdOrOffered; // 1 - created, 2 - offered
        uint112 offerAmount;
        address amountAddress;
    }

    uint256 internal swapCounter = 1;

    mapping(uint256 => SwapDetails) public swapToken;
    mapping(uint256 => SwapDetails) public offerToken;

    event Transfer1();

    function swap721(uint256 tokenId, address collectionAddress) public {
        require(msg.sender == ERC721(collectionAddress).ownerOf(tokenId), "NOT_OWNER");

        SwapDetails memory swapDetail;

        swapDetail.collectionAddress = collectionAddress;
        swapDetail.tokenId = tokenId;
        swapDetail.tokenOwner = msg.sender;
        swapDetail.createdOrOffered = 1;

        swapToken[swapCounter] = swapDetail;

        ERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        emit Transfer1();

        ++ swapCounter;
    }

    function offerToSwap(
        uint256 swapId, 
        uint256 tokenId, 
        address collectionAddress, 
        address amountAddress,
        uint112 amount
    ) public {
        require(swapToken[swapId].createdOrOffered == 1, "SWAP_NOT_CREATED");
        require(msg.sender == ERC721(collectionAddress).ownerOf(tokenId), "NOT_OWNER");

        SwapDetails memory offerDetail;

        offerDetail.collectionAddress = collectionAddress;
        offerDetail.tokenId = tokenId;
        offerDetail.tokenOwner = msg.sender;
        offerDetail.createdOrOffered = 2;

        if(amount == 0 && amountAddress == address(0)) {
            offerDetail.offerAmount = 0;
            offerDetail.amountAddress = address(0);
        }

        offerDetail.offerAmount = amount;
        offerDetail.amountAddress = amountAddress;

        offerToken[swapId] = offerDetail;

        ERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        ERC20(amountAddress).transferFrom(msg.sender, address(amountAddress), amount);
    }

    function acceptOffer(uint256 swapId, uint256 offerId) public {
        require(msg.sender == swapToken[swapId].tokenOwner, "NOT_SWAP_OWNER");
        require(swapToken[swapId].createdOrOffered == 1, "NOT_CREATED");
        require(offerToken[offerId].createdOrOffered == 2, "NOT_AN_OFFER");

        SwapDetails storage swapDetail = swapToken[swapId];
        SwapDetails storage offerDetail = offerToken[offerId];

        ERC721(swapDetail.collectionAddress).safeTransferFrom(address(this), offerDetail.tokenOwner, swapDetail.tokenId);
        ERC721(offerDetail.collectionAddress).safeTransferFrom(address(this), swapDetail.tokenOwner, offerDetail.tokenId);

        ERC20(offerDetail.amountAddress).transferFrom(address(this), swapDetail.tokenOwner, offerDetail.offerAmount);
    }

    function rejectOffer(uint256 swapId, uint256 offerId) public {
        require(msg.sender == swapToken[swapId].tokenOwner, "NOT_SWAP_OWNER");
        require(swapToken[swapId].createdOrOffered == 1, "NOT_CREATED");
        require(offerToken[offerId].createdOrOffered == 2, "NOT_AN_OFFER");

        SwapDetails storage offerDetail = offerToken[offerId];

        ERC721(offerDetail.collectionAddress).safeTransferFrom(address(this), offerDetail.tokenOwner, offerDetail.tokenId);

        offerDetail.createdOrOffered = 0;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }
}
