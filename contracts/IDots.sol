// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDots {
    enum State {
        // not started yet
        Loading,
        Started,
        Paused,
        Resumed,
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
        // grid size
        uint256 xWidth;
        // grid size
        uint256 yWidth;
        // increase rate
        uint256 epsilon;
        // every dot claim starts with this price
        uint256 claimBasePrice;
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
    event VestingSent(address indexed to, uint256 indexed vestingStake, uint256 amount);

    event GameStarted(
        uint256 indexed gameIndex,
        uint256 xWidth,
        uint256 yWidth,
        uint256 epsilon,
        uint256 claimBasePrice
    );
    event GamePaused(uint256 indexed gameIndex);
    event GameResumed(uint256 indexed gameIndex);
    event NewCountriesAdded(uint256 indexed newNumberOfCountries);

    error InvalidGame();
    error GameIsAlreadyStarted();
    error GameIsNotStarted();
    error GameIsNotPaused();
    error GameIsNotActive();
    error InsufficientBasePrice();
    error InsufficientPrice();
    error UndefinedCoordinates();
    error UndefinedCountry();
    error TxError();
    error NoVesting();

    function getGame(uint256 gameIndex) external view returns (Game memory);
}
