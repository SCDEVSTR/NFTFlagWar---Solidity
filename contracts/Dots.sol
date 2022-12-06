// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDots.sol";

contract Dots is IDots, Ownable {
    //TODO: Reusability
    uint256 public constant X_WIDTH = 50;
    uint256 public constant Y_WIDTH = 50;
    uint256 public constant EPSILON = 0.01 ether;
    uint256 public constant CLAIM_BASE_PRICE = 0.1 ether;

    State public gameState;

    mapping(uint256 => mapping(uint256 => Dot)) public dots;
    mapping(Country => uint256) public numberOfDotsOccupiedByCountry;
    uint256 public treasury;

    constructor() {
        gameState = State.Available;
    }

    function claimLocation(
        uint256 x,
        uint256 y,
        Country country
    ) public payable {
        Dot memory dotMemory = dots[x][y];

        if (gameState != State.Available) revert GameIsNotActive();
        if (msg.value < CLAIM_BASE_PRICE) revert InsufficientBasePrice();
        if (msg.value < dotMemory.lastPrice + EPSILON) revert InsufficientPrice();
        if (x > X_WIDTH - 1 || y > Y_WIDTH - 1) revert UndefinedCoordinates();
        if (country == Country.Nulland || country > Country.UnitedStates) revert UndefinedCountry();

        address lastOwner = dotMemory.owner;

        if (numberOfDotsOccupiedByCountry[dotMemory.country] > 0) {
            numberOfDotsOccupiedByCountry[dotMemory.country] -= 1;
        }

        numberOfDotsOccupiedByCountry[country] += 1;

        Dot storage dot = dots[x][y];

        dot.lastPrice = msg.value;
        dot.owner = msg.sender;
        dot.country = country;

        emit Transfer(x, y, msg.value, dotMemory.lastPrice, country, dotMemory.country);

        //game over if one country claimed every point
        if (numberOfDotsOccupiedByCountry[country] == (X_WIDTH * Y_WIDTH)) {
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

    function getGameBoard() public view returns (Dot[Y_WIDTH][X_WIDTH] memory board) {
        for (uint256 j = 0; j < X_WIDTH; j++) {
            for (uint256 i = 0; i < Y_WIDTH; i++) {
                board[j][i] = dots[j][i];
            }
        }
    }
}
