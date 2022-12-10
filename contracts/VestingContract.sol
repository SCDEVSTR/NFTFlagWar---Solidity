// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IDots.sol";
import "hardhat/console.sol";

abstract contract VestingContract is IDots {
    IDots public dotContract;

    constructor() {
        dotContract = IDots(address(this));
    }

    function foo() public view {
        console.log(dotContract.xWidth());
    }

    // function withdrawVesting() public {
    //     if (gameState != State.Completed) revert GameIsActive();
    //     uint256 vestingStake = vestingStakes[msg.sender];
    //     if (vestingStake <= 0) revert NoVesting();
    //     uint256 totalVestingAmount = address(this).balance - 250 ether - treasury;
    //     //solhint-disable-next-line
    //     (bool success, ) = payable(msg.sender).call{ value: (vestingStake / (Y_WIDTH * X_WIDTH)) * totalVestingAmount }(
    //         ""
    //     );
    //     if (!success) revert TxError();
    //     emit VestingSent(msg.sender, vestingStake, (vestingStake / (Y_WIDTH * X_WIDTH)) * totalVestingAmount);
    // }
}
