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

        // Split every games accounting
        // mapping(uint256 => LibraryContract.Game) public games;

        // Treasury Amount
        uint256 treasury;
        
        // Game state
        State state;
        
        // Grid x coordinate size
        uint256 xWidth;
        
        // Grid y coordinate size
        uint256 yWidth;
        
        // Price minimum increase rate
        uint256 epsilon;
        
        // Game starting price
        uint256 claimBasePrice;
    }

    enum State {
       
        Loading,
        Started,
        Paused,
        Resumed,
        Completed
    }
   
}
