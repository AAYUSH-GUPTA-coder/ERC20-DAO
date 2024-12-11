// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MyGovernor} from "../src/MyGoverner.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/Timelock.sol";
import {GovToken} from "../src/GovToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyGovernortest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timelock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    // timelock
    uint256 public constant MIN_DELAY = 3600; // after the voting period is over, wait MIN_DELAY time to execute the proposal
    uint256 public constant VOTING_DELAY = 1; // how many blocks, votes are active
    uint256 public constant VOTING_PERIOD = 50400; // how many blocks, votes are active

    address[] proposers;
    address[] executors;

    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        // delegate the token to ourself
        govToken.delegate(USER);
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        governor = new MyGovernor(govToken, timelock);

        // Roles
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, USER);

        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdateBox() public {
        uint256 valueToStore = 888;
        string memory description = "store 888 in box";
        bytes memory encodedFunnctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        values.push(0);
        calldatas.push(encodedFunnctionCall);
        targets.push(address(box));

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        console.log("Proposal Id", proposalId);

        //  View the state
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State after timewarp :", uint256(governor.state(proposalId)));

        // 2. Vote
        string memory reason = "bcoz Web3 is Cool!";
        uint8 voteWay = 1; // For / Voting Yes

        vm.prank(USER);
        uint256 value = governor.castVoteWithReason(proposalId, voteWay, reason);
        console.log("Vote Casted:", value);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State After Vote:", uint256(governor.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        console.log("Proposal State After Queue:", uint256(governor.state(proposalId)));

        // 4. Execute
        governor.execute(targets, values, calldatas, descriptionHash);

        console.log("Proposal State After Execute:", uint256(governor.state(proposalId)));

        assert(box.getNumber() == valueToStore);
        console.log("Box Value: ", box.getNumber());
    }
}
