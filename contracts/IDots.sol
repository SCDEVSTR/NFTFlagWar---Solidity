// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDots {
    //TODO: add cancelled state ?
    enum State {
        Available,
        Paused,
        Completed
    }

    struct Dot {
        address owner;
        uint256 country;
        uint256 lastPrice;
    }

    event Transfer(
        uint256 indexed x,
        uint256 indexed y,
        uint256 indexed price,
        uint256 oldPrice,
        uint256 newCountry,
        uint256 oldCountry
    );

    event GameEnded(uint256 winnerCountry);
    event StateChanged(State indexed newState);

    error GameIsNotActive();
    error GameIsActive();
    error InsufficientBasePrice();
    error InsufficientPrice();
    error UndefinedCoordinates();
    error UndefinedCountry();
    error TxError();
}
