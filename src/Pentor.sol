// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC20.sol";

struct Swap {
    address collectionAddress;
    address tokenOwner;
    uint256 tokenId;
}

struct Offer {
    uint256 swapId;
    uint112 offerAmount;
    uint256 tokenId;
    address collectionAddress;
    address amountAddress;
    address tokenOwner;
}

contract Pentor is ERC721TokenReceiver {

    uint256 internal swapCounter = 1;
    uint256 internal offerCounter = 1;

    mapping(uint256 => Swap) public swapToken;
    mapping(uint256 => Offer) public offerToken;

    function swap721(uint256 tokenId, address collectionAddress) public {
        require(msg.sender == ERC721(collectionAddress).ownerOf(tokenId), "NOT_OWNER");

        Swap memory swapDetail;

        swapDetail.collectionAddress = collectionAddress;
        swapDetail.tokenId = tokenId;
        swapDetail.tokenOwner = msg.sender;

        swapToken[swapCounter] = swapDetail;

        ERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        ++ swapCounter;
    }

    function offerToSwap(
        uint256 swapId, 
        uint256 tokenId, 
        address collectionAddress, 
        address amountAddress,
        uint112 amount
    ) public {
        require(swapToken[swapId].collectionAddress != address(0), "NOT_AVAILABLE");
        require(msg.sender == ERC721(collectionAddress).ownerOf(tokenId), "NOT_OWNER");

        Offer memory offerDetail;

        offerDetail.swapId = swapId;
        offerDetail.collectionAddress = collectionAddress;
        offerDetail.tokenId = tokenId;
        offerDetail.tokenOwner = msg.sender;

        if(amount == 0 && amountAddress == address(0)) {
            offerDetail.offerAmount = 0;
            offerDetail.amountAddress = address(0);
        }

        offerDetail.offerAmount = amount;
        offerDetail.amountAddress = amountAddress;

        offerToken[offerCounter] = offerDetail;

        ERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        ERC20(amountAddress).transferFrom(msg.sender, address(this), amount);

        ++offerCounter;
    }

    function acceptOffer(uint256 swapId, uint256 offerId) public {
        require(msg.sender == swapToken[swapId].tokenOwner, "NOT_SWAP_OWNER");
        require(offerToken[offerId].swapId == swapId, "NOT_AN_OFFER");

        Swap storage swapDetail = swapToken[swapId];
        Offer storage offerDetail = offerToken[offerId];

        ERC721(swapDetail.collectionAddress).transferFrom(address(this), offerDetail.tokenOwner, swapDetail.tokenId);
        ERC721(offerDetail.collectionAddress).transferFrom(address(this), swapDetail.tokenOwner, offerDetail.tokenId);

        ERC20(offerDetail.amountAddress).transferFrom(address(this), swapDetail.tokenOwner, offerDetail.offerAmount);
    }

    function rejectOffer(uint256 offerId) public {
        uint256 swapId = offerToken[offerId].swapId;

        require(msg.sender == swapToken[swapId].tokenOwner, "NOT_OWNER");

        Offer storage offerDetail = offerToken[offerId];

        ERC721(offerDetail.collectionAddress).safeTransferFrom(address(this), offerDetail.tokenOwner, offerDetail.tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
