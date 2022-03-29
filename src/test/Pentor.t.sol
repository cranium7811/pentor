// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/stdlib.sol";
import "solmate/test/utils/mocks/MockERC721.sol";
import "solmate/tokens/ERC20.sol";
import "../Pentor.sol";

contract ContractTest is DSTest, stdCheats {

    Pentor public pentor;
    Vm public vm = Vm(HEVM_ADDRESS);
    
    ERC20 public weth;
    address public immutable wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    MockERC721 public mock1;
    MockERC721 public mock2;

    function setUp() public {
        pentor = new Pentor();
        weth = ERC20(wethAddress);

        mock1 = new MockERC721("MOCK1", "M1"); 
        mock2= new MockERC721("MOCK2", "M2"); 
    }

    function testSwap721() public {

        mock1.mint(address(this), 1);
        mock1.approve(address(pentor), 1);
        pentor.swap721(1, address(mock1));
        
        Swap memory swapDetail = Swap({
            collectionAddress: address(mock1),
            tokenOwner: address(this),
            tokenId: 1
        });

        (address collectionAddress, address tokenOwner, uint256 tokenId) = pentor.swapToken(1);

        assertEq(mock1.ownerOf(1), address(pentor));
        assertEq(swapDetail.collectionAddress, collectionAddress);
        assertEq(swapDetail.tokenOwner, tokenOwner);
        assertEq(swapDetail.tokenId, tokenId);
    }

    function testOfferToSwap() public {
        mock1.mint(address(this), 1);
        mock1.approve(address(pentor), 1);
        pentor.swap721(1, address(mock1));

        uint256 pentorWeth = ERC20(wethAddress).balanceOf(address(pentor));

        vm.startPrank(address(0xBEEF));
        mock2.mint(address(0xBEEF), 1);
        weth.approve(address(pentor), 1e18);
        mock2.approve(address(pentor), 1);
        tip(address(wethAddress), address(0xBEEF), 2e18);
        pentor.offerToSwap(1, 1, address(mock2), address(weth), 1e18);
        vm.stopPrank();

        Offer memory offerDetail = Offer({
            swapId: 1,
            collectionAddress: address(mock2),
            tokenOwner: address(0xBEEF),
            tokenId: 1,
            offerAmount: 1e18,
            amountAddress: address(wethAddress)
        });

        (
            uint256 swapId,
            uint112 offerAmount,
            uint256 tokenId,
            address collectionAddress,
            address amountAddress,
            address tokenOwner
        ) = pentor.offerToken(1);

        assertEq(mock2.ownerOf(1), address(pentor));
        assertEq(offerDetail.swapId, swapId);
        assertEq(offerDetail.collectionAddress, collectionAddress);
        assertEq(offerDetail.tokenOwner, tokenOwner);
        assertEq(offerDetail.tokenId, tokenId);
        assertEq(offerDetail.offerAmount, offerAmount);
        assertEq(offerDetail.amountAddress, amountAddress);
        assertEq(ERC20(wethAddress).balanceOf(address(pentor)), pentorWeth + 1e18);
        assertEq(ERC20(wethAddress).balanceOf(address(0xBEEF)), 1e18);
        console.logAddress(offerDetail.tokenOwner);
    }

    function testAcceptOffer() public {
        mock1.mint(address(this), 1);
        mock1.approve(address(pentor), 1);
        pentor.swap721(1, address(mock1));

        uint256 pentorWeth = ERC20(wethAddress).balanceOf(address(pentor));
        uint256 thisWeth = ERC20(wethAddress).balanceOf(address(this));

        vm.startPrank(address(0xBEEF));
        mock2.mint(address(0xBEEF), 1);
        weth.approve(address(pentor), 1e18);
        mock2.approve(address(pentor), 1);
        tip(address(wethAddress), address(0xBEEF), 1e18);
        pentor.offerToSwap(1, 1, address(mock2), address(weth), 1e18);
        vm.stopPrank();

        pentor.acceptOffer(1, 1);

        assertEq(mock1.ownerOf(1), address(0xBEEF));
        assertEq(mock2.ownerOf(1), address(this));
        assertEq(ERC20(wethAddress).balanceOf(address(this)), thisWeth + 1e18);
        assertEq(ERC20(wethAddress).balanceOf(address(pentor)), pentorWeth);
        assertEq(ERC20(wethAddress).balanceOf(address(0xBEEF)), 0);
    }

    function testRejectOffer() public {
        mock1.mint(address(this), 1);
        mock1.approve(address(pentor), 1);
        pentor.swap721(1, address(mock1));

        uint256 pentorWeth = ERC20(wethAddress).balanceOf(address(pentor));
        uint256 thisWeth = ERC20(wethAddress).balanceOf(address(this));

        vm.startPrank(address(0xBEEF));
        mock2.mint(address(0xBEEF), 1);
        weth.approve(address(pentor), 1e18);
        mock2.approve(address(pentor), 1);
        tip(address(wethAddress), address(0xBEEF), 1e18);
        pentor.offerToSwap(1, 1, address(mock2), address(weth), 1e18);
        vm.stopPrank();

        pentor.rejectOffer(1);

        assertEq(mock1.ownerOf(1), address(pentor));
        assertEq(mock2.ownerOf(1), address(0xBEEF));
        assertEq(ERC20(wethAddress).balanceOf(address(this)), thisWeth);
        assertEq(ERC20(wethAddress).balanceOf(address(pentor)), pentorWeth);
        assertEq(ERC20(wethAddress).balanceOf(address(0xBEEF)), 1e18);
    }
}
