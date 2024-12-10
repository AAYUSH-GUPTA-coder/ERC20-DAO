// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    // minDelay is how much long you have to wait before executing
    // proposers is the list of addresses that can propose
    // executors is the list of addresses that can execute
    constructor(uint256 _minDelay, address[] memory proposers, address[] memory executors)
        TimelockController(_minDelay, proposers, executors, msg.sender)
    {
        
    }
}
