// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDots {
    enum Country {
        Nulland,
        Argentina,
        Australia,
        Brazil,
        Canada,
        China,
        France,
        Germany,
        India,
        Indonesia,
        Italy,
        Japan,
        Korea,
        Mexico,
        Russia,
        SaudiArabia,
        SouthAfrica,
        Turkey,
        Ukraine,
        UnitedKingdom,
        UnitedStates
    }

    enum State {
        Available,
        Paused,
        Completed
    }

    struct Dot {
        address owner;
        Country country;
        uint256 lastPrice;
    }

    event Transfer(uint256 indexed x, uint256 indexed y, uint256 indexed price, Country newCountry);
    event GameEnded(Country winnerCountry);

    error GameIsNotActive();
    error GameIsActive();
    error InsufficientBasePrice();
    error InsufficientPrice();
    error UndefinedCoordinates();
    error UndefinedCountry();
    error TxError();
}
