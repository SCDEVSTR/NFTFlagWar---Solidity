// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./LibraryContract.sol";

interface IDots {
    

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
    error GameIsActive();
    error InsufficientBasePrice();
    error InsufficientPrice();
    error UndefinedCoordinates();
    error UndefinedCountry();
    error TxError();
    error NoVesting();

   function getGame(uint256 gameIndex) external view returns (LibraryContract.Game memory);
}
