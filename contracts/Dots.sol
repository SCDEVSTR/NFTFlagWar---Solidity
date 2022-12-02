// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Dots is Ownable, ReentrancyGuard {
    enum Types {
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

    uint256 public constant x_width = 50;
    uint256 public constant y_width = 50;
    uint256 public constant EPSILON = 0.01 ether;
    uint256 public constant CLAIM_BASE_PRICE = 0.1 ether;

    State public state;

    mapping(uint256 => mapping(uint256 => Dot)) public lots;
    mapping(Types => uint256) public dist;
    Types[x_width][y_width] public slate;
    //mapping (address=>uint) public balances;
    struct Dot {
        address owner;
        Types country;
        uint256 last_price;
    }

    event Transfer(uint256 indexed x, uint256 indexed y, uint256 indexed price, Types new_country);

    constructor() {
        state = State.Available;
    }

    function claimLocation(
        uint256 x,
        uint256 y,
        Types country
    ) public payable nonReentrant {
        require(msg.sender == tx.origin, "Contracts can't bid");
        require(state == State.Available, "Game is paused or ended");
        require(msg.value >= CLAIM_BASE_PRICE, "lower-bound unsatisfied");
        require(msg.value >= lots[x][y].last_price + EPSILON, "delta_bid must be geq to epsilon");
        require(x <= x_width && y <= y_width, "undefined coordinates");
        require(Types.Nulland < country && country <= Types.UnitedStates, "undefined country");
        //fee %.1 for location transactions
        (bool success, ) = payable(lots[x][y].owner).call{ value: (msg.value * 999) / 1000 }("");
        require(success, "fail during payment");
        if (dist[lots[x][y].country] > 0) {
            dist[lots[x][y].country] -= 1;
        }
        dist[country] += 1;
        slate[x][y] = country;

        lots[x][y].last_price = msg.value;
        lots[x][y].owner = msg.sender;
        lots[x][y].country = country;

        emit Transfer(x, y, msg.value, country);
        //game over if one country claimed every point
        if (dist[country] == (x_width * y_width)) {
            state = State.Completed;
        }
    }

    function setState(State new_state) public onlyOwner {
        state = new_state;
    }

    function claimOwnerCut() public onlyOwner {
        /// @TODO: Mechanism design for protocol cuts
        require(state == State.Completed, "Game is not ended yet.");

        (bool success, ) = payable(owner()).call{ value: (address(this).balance * 15) / 100 }("");
        require(success, "claim failed");
    }

    function returnSlate() public view returns (Types[x_width][y_width] memory arr) {
        return slate;
    }

    /*
	function recoverBalance() public {
		require(balances[msg.sender] > 0, "You have no balance to recover");
		(bool success, ) = payable(msg.sender).call{value:balances[msg.sender]}("");
		require(success,"Payment failed");
	}
*/
}
