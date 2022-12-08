// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDots.sol";

contract Dots is IDots, Ownable {
    uint256 public xWidth = 50;
    uint256 public yWidth = 50;
    uint256 public epsilon = 0.01 ether;
    uint256 public claimBasePrice = 0.1 ether;

    State public gameState;

    // gameID => Y index => X index => Dot
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Dot))) public dots;
    // gameID => country => numberOfDotsOccupiedByCountry
    mapping(uint256 => mapping(uint256 => uint256)) public numberOfDotsOccupiedByCountry;

    uint256 public treasury;
    // we can add mapping integer to string(country name) to put countries in the blockchain
    uint256 public numberOfCountries = 20;

    constructor() {
        gameState = State.Available;
    }

    function claimLocation(
        uint256 gameIndex,
        uint256 y,
        uint256 x,
        uint256 country
    ) public payable {
        Dot memory dotMemory = dots[gameIndex][y][x];

        if (gameState != State.Available) revert GameIsNotActive();
        if (msg.value < claimBasePrice) revert InsufficientBasePrice();
        if (msg.value < dotMemory.lastPrice + epsilon) revert InsufficientPrice();
        if (x > xWidth - 1 || y > yWidth - 1) revert UndefinedCoordinates();
        if (country == 0 || country > numberOfCountries) revert UndefinedCountry();

        address lastOwner = dotMemory.owner;

        if (numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] > 0) {
            numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] -= 1;
        }

        numberOfDotsOccupiedByCountry[gameIndex][country] += 1;

        Dot storage dot = dots[gameIndex][y][x];

        dot.lastPrice = msg.value;
        dot.owner = msg.sender;
        dot.country = country;

        emit Transfer(gameIndex, y, x, msg.value, dotMemory.lastPrice, country, dotMemory.country);

        //game over if one country claimed every point
        if (numberOfDotsOccupiedByCountry[gameIndex][country] == (xWidth * yWidth)) {
            gameState = State.Completed;
            emit GameEnded(country);
        }

        treasury += dotMemory.lastPrice / 1000;

        // if it is first claim then there is no returning money
        if (lastOwner != address(0)) {
            //solhint-disable-next-line
            (bool success, ) = payable(lastOwner).call{ value: (dotMemory.lastPrice * 999) / 1000 }("");
            if (!success) revert TxError();
        }
    }

    function setState(State newState) public onlyOwner {
        gameState = newState;
        emit StateChanged(newState);
    }

    function claimTreasury() public onlyOwner {
        uint256 lastTreasury = treasury;
        treasury = 0;

        //solhint-disable-next-line
        (bool success, ) = payable(owner()).call{ value: lastTreasury }("");
        if (!success) revert TxError();
    }

    function setNumberOfCountries(uint256 _numberOfCountries) external onlyOwner {
        numberOfCountries = _numberOfCountries;
    }

    function setXWidth(uint256 _xWidth) external onlyOwner {
        xWidth = _xWidth;
    }

    function setYWidth(uint256 _yWidth) external onlyOwner {
        yWidth = _yWidth;
    }

    function setEpsilon(uint256 _epsilon) external onlyOwner {
        epsilon = _epsilon;
    }

    function setBasePrice(uint256 _claimBasePrice) external onlyOwner {
        claimBasePrice = _claimBasePrice;
    }
}
