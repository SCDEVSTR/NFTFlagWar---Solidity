// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IDots.sol";

abstract contract VestingContract is IDots {
    IDots public dotContract;
    mapping(uint256 => mapping(address => uint256)) public vestingStakes;

    constructor() {
        dotContract = IDots(address(this));
    }

    // @dev We need to keep track of each game's width and height
    function withdrawVesting(uint256 gameIndex) public {
        Game memory game = dotContract.getGame(gameIndex); // Get the information about the game
        if (game.state != State.Completed) revert GameIsActive(); // Check if the game is completed
        uint256 vestingStake = vestingStakes[gameIndex][msg.sender];
        if (vestingStake <= 0) revert NoVesting();
        uint256 totalVestingAmount = game.treasury;
        vestingStakes[gameIndex][msg.sender] = 0;
        uint256 totalValue = (vestingStake * totalVestingAmount) / (dotContract.yWidth() * dotContract.xWidth());
        //solhint-disable-next-line
        (bool success, ) = payable(msg.sender).call{ value: totalValue }("");
        if (!success) revert TxError();
        emit VestingSent(msg.sender, vestingStake, totalValue);
    }
}
