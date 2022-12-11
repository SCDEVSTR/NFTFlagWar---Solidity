// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDots {
    enum State {
        // not started yet
        Loading,
        //started
        Started,
        Paused,
        Completed
    }

    struct Dot {
        address owner;
        uint256 country;
        uint256 lastPrice;
    }

    struct Game {
        // treasury will be distributed to winners
        uint256 treasury;
        // the state of game
        State state;
    }

    event Transfer(
        uint256 indexed gameIndex,
        uint256 y,
        uint256 x,
        uint256 price,
        uint256 oldPrice,
        uint256 indexed newCountry,
        uint256 oldCountry
    );

    event GameEnded(uint256 indexed gameIndex, uint256 indexed winnerCountry);
    event StateChanged(State indexed newState);
    event BoardCleared();
    event VestingSent(address indexed to, uint256 indexed vestingStake, uint256 amount);

    error InvalidGame();
    error GameIsNotActive();
    error GameIsActive();
    error InsufficientBasePrice();
    error InsufficientPrice();
    error UndefinedCoordinates();
    error UndefinedCountry();
    error TxError();
    error NoVesting();

    function xWidth() external view returns (uint256);

    function yWidth() external view returns (uint256);

    function getGame(uint256 gameIndex) external view returns (Game memory);
}
