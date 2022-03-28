// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "solmate/test/utils/mocks/MockERC721.sol";
import "../Pentor.sol";

contract ContractTest is DSTest {

    Pentor public pentor;
    Vm public vm = Vm(HEVM_ADDRESS);

    MockERC721 public mock1;
    MockERC721 public mock2;

    function setUp() public {
        pentor = new Pentor();

        mock1 = new MockERC721("MOCK1", "M1"); 
        mock2= new MockERC721("MOCK2", "M2"); 
    }

    function testSwap721() public {

        mock1.mint(address(this), 1);

        vm.startPrank(address(0xBEEF));
        mock2.mint(address(0xBEEF), 1);
        vm.stopPrank();

        mock1.approve(address(pentor), 1);

        pentor.swap721(1, address(mock1));

        assertEq(mock1.ownerOf(1), address(pentor));
    }
}
