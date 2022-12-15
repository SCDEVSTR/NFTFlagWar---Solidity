// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
library LibraryContract  {

    struct Dot {
        //  gameID => Y index => X index => Dot
        //  mapping(uint256 => mapping(uint256 => mapping(uint256 => Dot))) public dots;

        //Who is owner of flag
        address owner;
        // Which is country of flag
        uint256 country;
        // Which is last price of flag
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

    enum State {
        // not started yet
        Loading,
        Started,
        Paused,
        Resumed,
        Completed
    }


   
}
