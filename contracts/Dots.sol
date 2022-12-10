// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDots.sol";
import "./VestingContract.sol";

contract Dots is IDots, Ownable, VestingContract {
    // grid size
    uint256 public override xWidth = 50;
    // grid size
    uint256 public yWidth = 50;
    // increase rate
    uint256 public epsilon = 0.01 ether;
    // every dot claim starts with this price
    uint256 public claimBasePrice = 0.1 ether;
    // current game
    uint256 public activeGameIndex = 0;

    // gameID => Y index => X index => Dot
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Dot))) public dots;
    // gameID => country => numberOfDotsOccupiedByCountry
    mapping(uint256 => mapping(uint256 => uint256)) public numberOfDotsOccupiedByCountry;

    // split every games accounting
    mapping(uint256 => Game) public games;
    // how many country do we have
    uint256 public numberOfCountries = 20;

    function claimLocation(
        uint256 gameIndex,
        uint256 y,
        uint256 x,
        uint256 country
    ) public payable {
        Dot memory dotMemory = dots[gameIndex][y][x];
        Game storage game = games[gameIndex];

        // only play active game
        if (gameIndex != activeGameIndex) revert InvalidGame();
        // check state of current game
        if (game.state != State.Started) revert GameIsNotActive();
        //check for first claim
        if (msg.value < claimBasePrice) revert InsufficientBasePrice();
        // check for reclaims
        if (msg.value < dotMemory.lastPrice + epsilon) revert InsufficientPrice();
        // validate coordinates
        if (x > xWidth - 1 || y > yWidth - 1) revert UndefinedCoordinates();
        // validate country
        if (country == 0 || country > numberOfCountries) revert UndefinedCountry();

        address lastOwner = dotMemory.owner;
        //decrement number of dot for current country
        if (numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] > 0) {
            numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] -= 1;
        }
        // increment number of dot for current country
        numberOfDotsOccupiedByCountry[gameIndex][country] += 1;

        Dot storage dot = dots[gameIndex][y][x];

        dot.lastPrice = msg.value;
        dot.owner = msg.sender;
        dot.country = country;

        emit Transfer(gameIndex, y, x, msg.value, dotMemory.lastPrice, country, dotMemory.country);

        //game over if one country claimed every point
        if (numberOfDotsOccupiedByCountry[gameIndex][country] == (xWidth * yWidth)) {
            activeGameIndex++;
            game.state = State.Completed;
            emit GameEnded(gameIndex, country);
        }

        // if it is first claim, claimBasePrice goes to treasury

        if (lastOwner == address(0)) {
            game.treasury += msg.value;
        } else {
            // if it is reclaim, send claimers money to older claimer
            // ex: claimed for 1000 eth, then reclaimer claimed for a 2000 eth
            // then send 2000 eth (- %0.1 fee) to older claimer
            game.treasury += msg.value / 1000;
            //solhint-disable-next-line
            (bool success, ) = payable(lastOwner).call{ value: (msg.value * 999) / 1000 }("");
            if (!success) revert TxError();
        }
    }

    //change the game state of game @param gameIndex
    function changeGameState(uint256 gameIndex, State newState) public onlyOwner {
        games[gameIndex].state = newState;
        emit StateChanged(newState);
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
