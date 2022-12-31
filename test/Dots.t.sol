// SPDX-License-Identifier:GPL-3.0-or-later
pragma solidity ^0.8.7;

import "src/Dots.sol";
import "forge-std/Test.sol";

contract DotsTest is Test {

    Dots public dots;

    address alice;
    address bob;
    address owner;
    address attacker;

    function setUp() public {
      
    dots = new  Dots();

    //Treasury 

    owner = dots.owner();
   
    //emit log_named_address("Treasury 1 ", owner);
    //emit log_named_address("Treasury 2 ", address(this));
    //emit log_named_address("Treasury 3 ", msg.sender);

    emit log_named_address("Treasury", address(dots));
    emit log_named_decimal_uint("Treasury balance is ", address(dots).balance, 18);

    //Game Starting 00 01 10 11 We have 4 dots 
    //If you dont start this, you gives the GameIsNotActive() error

    vm.prank(owner);
    dots.startGame(2, 2, 0.1 ether, 0.0001 ether);
   

    //Alice

    //alice = vm.addr(1);
    alice = makeAddr("Alice");
    vm.deal(alice, 100 ether);
    emit log_named_address("Alice", alice);
    emit log_named_decimal_uint("Alice balance is", address(alice).balance, 18);

    //Bob

    //bob = vm.addr(2);
    bob =  makeAddr("Bob");
    vm.deal(bob, 100 ether);
    emit log_named_address("Bob", bob);
    emit log_named_decimal_uint("Bob balance is", address(bob).balance, 18);

    //Attacker

    //attacker = vm.addr(3);
    attacker =  makeAddr("Attacker");
    vm.deal(attacker, 100 ether);
    emit log_named_address("Attacker ", attacker);
    emit log_named_decimal_uint("Attacker balance is", address(attacker).balance, 18);
   
    
    }

    //testGameIndexNumber
    function testGameIndexNumber() public {
        assertEq(dots.activeGameIndex(), 0);
    }

    //testCountriesNumber
    function testCountriesNumber() public {
     assertEq(dots.numberOfCountries(),20);
    }

    //testFailCountriesNumber
    function testFailCountriesNumber() public {
        assertEq(dots.numberOfCountries(),25);
    }

    //testFailStartFunction
    function testFailStartFunction() public {
        vm.prank(alice);
        dots.startGame(1,2,3,4);
    }

    //testFailInsufficientBasePrice
    function testFailInsufficientBasePrice() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.01 ether}(1,1,8);
        vm.stopPrank();
    }

    //testInsufficientBasePrice
    function testInsufficientBasePrice() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,1,8);
        vm.stopPrank();
    }

    //testInsufficientPrice
    function testInsufficientPrice() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,1,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 0.2 ether}(1,1,8);
        vm.stopPrank();
    }

    //testFailInsufficientPrice
    function testFailInsufficientPrice() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,1,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 0.1 ether}(1,1,8);
        vm.stopPrank();
    }

    //testUndefinedCoordinates
    function testUndefinedCoordinates() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,1,8);
        vm.stopPrank();
    }

    //testFailUndefinedCoordinates
     function testFailUndefinedCoordinates() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,20,8);
        vm.stopPrank();  
    }

    //testUndefinedCountry
     function testUndefinedCountry() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,1,8);
        vm.stopPrank();
    }

     //testFailUndefinedCountry
     function testFailUndefinedCountry() public {
        vm.startPrank(alice);
        dots.claimLocation{value: 0.1 ether}(1,1,25);
        vm.stopPrank();  
    }

    //testGameState | enum State { Loading,Started,Paused,Completed}
    function testGameState() public {
        (, IDots.State state,,,,) = dots.games(dots.activeGameIndex());
        assertEq(uint8(state),1);
    }

    //testGamePaused | enum State { Loading,Started,Paused,Completed}
    function testGamePaused() public {
        vm.prank(owner);
        dots.pauseGame();
         (, IDots.State state,,,,) = dots.games(dots.activeGameIndex());
        assertEq(uint8(state),2);
    }

    //testGameResumed | enum State { Loading,Started,Paused,Completed}
    function testGameResumed()  public {
        vm.prank(owner);
        dots.pauseGame();
        dots.resumeGame();
         (, IDots.State state,,,,) = dots.games(dots.activeGameIndex());
        assertEq(uint8(state),1);

    }
    //testFailGameCompleted| enum State { Loading,Started,Paused,Completed}
    function testFailGameCompleted() public {
        vm.prank(owner);
        (, IDots.State state,,,,) = dots.games(dots.activeGameIndex());
        assertEq(uint8(state),3);

    }

    //testSetNumberOfCountries
    function testSetNumberOfCountries() public {
        vm.prank(owner);
        dots.setNumberOfCountries(25);
    }

    //testFailSetNumberOfCountries
    function testFailSetNumberOfCountries() public {
        vm.prank(alice);
        dots.setNumberOfCountries(25);
    }

    
    function testFinishedGame() public {
        
        vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(1,1,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 2 ether}(1,1,8);
        vm.stopPrank();
         vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(1,0,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 2 ether}(1,0,8);
        vm.stopPrank();
         vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(0,1,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 2 ether}(0,1,8);
        vm.stopPrank();
        vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(0,0,8);
        vm.stopPrank();
        
        emit log_named_decimal_uint("New Treasury balance is ", address(dots).balance, 18);
        emit log_named_decimal_uint("New Alice balance is", address(alice).balance, 18);
        emit log_named_decimal_uint("New Bob balance is", address(bob).balance, 18);
        emit log_named_decimal_uint("New Attacker balance is", address(attacker).balance, 18);
    
    }

    function testFailFinishedGame() public {
        
        vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(1,1,6);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 1 ether}(1,0,6);
        vm.stopPrank();
        vm.startPrank(alice);
        dots.claimLocation{value: 2 ether}(0,1,6);
        vm.stopPrank();
        vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(0,0,6);
        vm.stopPrank();
        vm.startPrank(attacker);
        dots.claimLocation{value: 2 ether}(0,0,6);
        vm.stopPrank();
        
        emit log_named_decimal_uint("New Treasury balance is ", address(dots).balance, 18);
        emit log_named_decimal_uint("New Alice balance is", address(alice).balance, 18);
        emit log_named_decimal_uint("New Bob balance is", address(bob).balance, 18);
        emit log_named_decimal_uint("New Attacker balance is", address(attacker).balance, 18);
    
    }

    function testVesting() public {
        
        vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(1,1,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 2 ether}(1,1,8);
        vm.stopPrank();
        vm.startPrank(attacker);
        dots.claimLocation{value: 3 ether}(1,1,8);
        vm.stopPrank();
         vm.startPrank(alice);
        dots.claimLocation{value: 1 ether}(1,0,8);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 2 ether}(1,0,8);
        vm.stopPrank();
        vm.startPrank(attacker);
        dots.claimLocation{value: 3 ether}(1,0,8);
        vm.stopPrank();
         vm.startPrank(attacker);
        dots.claimLocation{value: 1 ether}(0,1,8);
        emit log_named_decimal_uint("Pre Vesting Attacker balance is", address(attacker).balance, 18);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 2 ether}(0,1,8);
        vm.stopPrank();
        vm.startPrank(alice);
        dots.claimLocation{value: 3 ether}(0,1,8);
        emit log_named_decimal_uint("Pre Vesting Alice balance is", address(alice).balance, 18);
        vm.stopPrank();
        vm.startPrank(bob);
        dots.claimLocation{value: 1 ether}(0,0,8);
        emit log_named_decimal_uint("Pre Vesting Bob balance is", address(bob).balance, 18);
        emit log_named_decimal_uint("Pre Vesting Treasury balance is ", address(dots).balance, 18);
        vm.stopPrank();

        
        
      
        vm.startPrank(bob);
        //console.log(dots.vestingStakes(0,address(bob)));
        emit log_named_uint("Bob share is", dots.vestingStakes(0,address(bob)));
        dots.withdrawVesting((dots.activeGameIndex())-1);
        emit log_named_decimal_uint("Vesting Bob balance is", address(bob).balance, 18);
        vm.stopPrank();

        vm.startPrank(alice);
        //console.log(dots.vestingStakes(0,address(alice)));
        emit log_named_uint("Alice share is", dots.vestingStakes(0,address(alice)));
        dots.withdrawVesting((dots.activeGameIndex())-1); 
        emit log_named_decimal_uint("Vesting Alice balance is", address(alice).balance, 18);
        vm.stopPrank();

        vm.startPrank(attacker);
        //console.log(dots.vestingStakes(0,address(attacker)));
        emit log_named_uint("Attacker share is", dots.vestingStakes(0,address(attacker)));
        dots.withdrawVesting((dots.activeGameIndex())-1);
        emit log_named_decimal_uint("Vesting Attacker balance is", address(attacker).balance, 18);
        emit log_named_decimal_uint("Vesting Treasury balance is ", address(dots).balance, 18);
        vm.stopPrank();

      

    
    }
 

}
