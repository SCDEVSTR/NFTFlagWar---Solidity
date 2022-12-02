// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDots.sol";

contract Dots is IDots, Ownable {
    uint256 public constant X_WIDTH = 50;
    uint256 public constant Y_WIDTH = 50;
    uint256 public constant EPSILON = 0.01 ether;
    uint256 public constant CLAIM_BASE_PRICE = 0.1 ether;

    State public gameState;

    mapping(uint256 => mapping(uint256 => Dot)) public dots;
    mapping(Country => uint256) public numberOfDotsOccupiedByCountry;
    Country[X_WIDTH][Y_WIDTH] public gameBoard;
    uint256 public protocolFee;

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
        if (dotMemory.lastPrice == 0 && msg.value < CLAIM_BASE_PRICE) revert InsufficientBasePrice();
        if (msg.value < dotMemory.lastPrice + EPSILON) revert InsufficientPrice();
        if (x > X_WIDTH || y > Y_WIDTH) revert UndefinedCoordinates();
        if (country == Country.Nulland || country > Country.UnitedStates) revert UndefinedCountry();

        address lastOwner = dotMemory.owner;

        protocolFee += msg.value / 1000;

        if (numberOfDotsOccupiedByCountry[dotMemory.country] > 0) numberOfDotsOccupiedByCountry[dotMemory.country] -= 1;

        numberOfDotsOccupiedByCountry[country] += 1;
        gameBoard[x][y] = country;

        Dot storage dot = dots[x][y];

        dot.lastPrice = msg.value;
        dot.owner = msg.sender;
        dot.country = country;

        emit Transfer(x, y, msg.value, country);

        //game over if one country claimed every point
        if (numberOfDotsOccupiedByCountry[country] == (X_WIDTH * Y_WIDTH)) {
            gameState = State.Completed;
            emit GameEnded(country);
        }

        //solhint-disable-next-line
        (bool success, ) = payable(lastOwner).call{ value: (dotMemory.lastPrice * 999) / 1000 }("");
        if (!success) revert TxError();
    }

    function setState(State newState) public onlyOwner {
        gameState = newState;
    }

    function claimOwnerCut() public onlyOwner {
        if (gameState != State.Completed) revert GameIsActive();
        //solhint-disable-next-line
        (bool success, ) = payable(owner()).call{ value: protocolFee }("");
        if (!success) revert TxError();
    }

    function returnSlate() public view returns (Country[X_WIDTH][Y_WIDTH] memory) {
        return gameBoard;
    }

    /*
	function recoverBalance() public {
		require(balances[msg.sender] > 0, "You have no balance to recover");
		(bool success, ) = payable(msg.sender).call{value:balances[msg.sender]}("");
		require(success,"Payment failed");
	}
*/
}