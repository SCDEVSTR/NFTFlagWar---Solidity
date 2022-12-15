// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDots.sol";
import "./VestingContract.sol";

//TODO: DISCUSS MULTISIG
//TODO: ADD CONTEXT MSG.SENDER
contract Dots is IDots, Ownable, VestingContract {
    // current game
    uint256 public activeGameIndex = 0;
    // gameID => Y index => X index => Dot
    // TODO: HASH WITH 0,4
    // mapping(uint256 => mapping(uint256 => mapping(uint256 => Dot))) public dots;
    // gameID => country => numberOfDotsOccupiedByCountry
    mapping(uint256 => mapping(uint256 => uint256)) public numberOfDotsOccupiedByCountry;

    // gameID => Y index => X index => Dot
    mapping(bytes32 => Dot) public dots;

    // split every games accounting
    mapping(uint256 => Game) public games;
    // how many country do we have,
    // Countries starts from 1, 0 is Nulland
    uint256 public numberOfCountries = 20;

    function claimLocation(
        uint256 y,
        uint256 x,
        uint256 country
    ) public payable {
        uint256 gameIndex = activeGameIndex;
        Dot memory dotMemory = dots[getDotIndex(activeGameIndex, y, x)];
        Game memory gameMemory = games[gameIndex];

        // check state of current game
        if (gameMemory.state != State.Started) revert GameIsNotActive();
        //check for first claim
        if (msg.value < gameMemory.claimBasePrice) revert InsufficientBasePrice();
        // check for reclaims
        if (msg.value < dotMemory.lastPrice + gameMemory.epsilon) revert InsufficientPrice();
        // validate coordinates
        if (x > gameMemory.xWidth - 1 || y > gameMemory.yWidth - 1) revert UndefinedCoordinates();
        // validate country
        if (country == 0 || country > numberOfCountries) revert UndefinedCountry();

        address lastOwner = dotMemory.owner;
        //decrement number of dot for current country
        if (numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] > 0) {
            numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] -= 1;
        }
        // increment number of dot for current country
        numberOfDotsOccupiedByCountry[gameIndex][country] += 1;

        Dot storage dot = dots[getDotIndex(activeGameIndex, y, x)];
        Game storage game = games[gameIndex];

        dot.lastPrice = msg.value;
        dot.owner = msg.sender;
        dot.country = country;

        emit Transfer(gameIndex, y, x, msg.value, dotMemory.lastPrice, country, dotMemory.country);

        //game over if one country claimed every point
        if (numberOfDotsOccupiedByCountry[gameIndex][country] == (gameMemory.xWidth * gameMemory.yWidth)) {
            activeGameIndex++;
            game.state = State.Completed;
            emit GameEnded(gameIndex, country);
        }

        // if it is first claim, claimBasePrice goes to treasury

        if (lastOwner == address(0)) {
            game.treasury += msg.value;
            vestingStakes[activeGameIndex][msg.sender] += 1;
        } else {
            // if it is reclaim, send claimers money to older claimer
            // ex: claimed for 1000 eth, then reclaimer claimed for a 2000 eth
            // then send 2000 eth (- %0.1 fee) to older claimer
            game.treasury += msg.value / 1000;
            vestingStakes[activeGameIndex][msg.sender] += 1;
            vestingStakes[activeGameIndex][lastOwner] -= 1;
            //solhint-disable-next-line
            (bool success, ) = payable(lastOwner).call{ value: (msg.value * 999) / 1000 }("");
            if (!success) revert TxError();
        }
    }

    // start the active game
    function startGame(
        uint256 xWidth,
        uint256 yWidth,
        uint256 claimBasePrice,
        uint256 epsilon
    ) external onlyOwner {
        if (games[activeGameIndex].state != State.Loading) revert GameIsAlreadyStarted();
        games[activeGameIndex] = Game({
            xWidth: xWidth,
            yWidth: yWidth,
            epsilon: epsilon,
            claimBasePrice: claimBasePrice,
            treasury: 0,
            state: State.Started
        });
        emit GameStarted(activeGameIndex, xWidth, yWidth, epsilon, claimBasePrice);
    }

    // pause the active game
    function pauseGame() external onlyOwner {
        if (games[activeGameIndex].state != State.Started) revert GameIsNotStarted();

        games[activeGameIndex].state = State.Paused;
        emit GamePaused(activeGameIndex);
    }

    // resume the active game
    function resumeGame() external onlyOwner {
        if (games[activeGameIndex].state != State.Paused) revert GameIsNotPaused();

        games[activeGameIndex].state = State.Started;
        emit GameResumed(activeGameIndex);
    }

    function setNumberOfCountries(uint256 _numberOfCountries) external onlyOwner {
        numberOfCountries = _numberOfCountries;
        emit NewCountriesAdded(_numberOfCountries);
    }

    function getGame(uint256 gameIndex) external view override returns (Game memory) {
        return games[gameIndex];
    }

    function getDotIndex(
        uint256 gameIndex,
        uint256 y,
        uint256 x
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(gameIndex, y, x));
    }
}
