// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    constructor() Ownable(msg.sender) {}

    uint256 private s_number;

    event NumberChanges(uint256 newNumber);

    function store(uint256 newNumber) external onlyOwner {
        s_number = newNumber;
        emit NumberChanges(newNumber);
    }

    function getNumber() external view returns (uint256) {
        return s_number;
    }
}
