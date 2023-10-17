// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyTokenV2} from "../src/MyTokenV2.sol";
import {MyTokenProxiable} from "../src/MyTokenProxiable.sol";
import {MyTokenProxiableV2} from "../src/MyTokenProxiableV2.sol";

import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract MyTokenTest is Test {

  function testUUPS() public {
    Proxy proxy = Upgrades.deployUUPSProxy(type(MyTokenProxiable).creationCode, abi.encodeCall(MyTokenProxiable.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeProxy(address(proxy), type(MyTokenProxiableV2).creationCode, msg.sender, abi.encodeCall(MyTokenProxiableV2.resetGreeting, ()));
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }

  function testTransparent() public {
    Proxy proxy = Upgrades.deployTransparentProxy(type(MyToken).creationCode, msg.sender, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));
    address adminAddress = Upgrades.getAdminAddress(address(proxy));

    assertFalse(adminAddress == address(0));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeProxy(address(proxy), type(MyTokenV2).creationCode, msg.sender, abi.encodeCall(MyTokenV2.resetGreeting, ()));
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));
    
    assertEq(Upgrades.getAdminAddress(address(proxy)), adminAddress);

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }

  function testBeacon() public {
    IBeacon beacon = Upgrades.deployBeacon(type(MyToken).creationCode, msg.sender);
    address implAddressV1 = beacon.implementation();

    Proxy proxy = Upgrades.deployBeaconProxy(address(beacon), abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    Upgrades.upgradeBeacon(address(beacon), type(MyTokenV2).creationCode, msg.sender);
    address implAddressV2 = beacon.implementation();

    MyTokenV2(address(instance)).resetGreeting();

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
  }

  function testUpgradeProxyWithImplAddress() public {
    Proxy proxy = Upgrades.deployTransparentProxy(type(MyToken).creationCode, msg.sender, abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));
    address implAddressV1 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    address newImpl = Upgrades.deployImplementation(type(MyTokenV2).creationCode);

    Upgrades.upgradeProxy(address(proxy), newImpl, msg.sender, abi.encodeCall(MyTokenV2.resetGreeting, ()));
    address implAddressV2 = Upgrades.getImplementationAddress(address(proxy));

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
    assertEq(newImpl, implAddressV2);
  }

  function testUpgradeBeaconWithImplAddress() public {
    IBeacon beacon = Upgrades.deployBeacon(type(MyToken).creationCode, msg.sender);
    address implAddressV1 = beacon.implementation();

    Proxy proxy = Upgrades.deployBeaconProxy(address(beacon), abi.encodeCall(MyToken.initialize, ("hello", msg.sender)));
    MyToken instance = MyToken(address(proxy));

    assertEq(instance.name(), "MyToken");
    assertEq(instance.greeting(), "hello");
    assertEq(instance.owner(), msg.sender);

    address newImpl = Upgrades.deployImplementation(type(MyTokenV2).creationCode);

    Upgrades.upgradeBeacon(address(beacon), newImpl, msg.sender);
    address implAddressV2 = beacon.implementation();

    MyTokenV2(address(instance)).resetGreeting();

    assertEq(instance.greeting(), "resetted");
    assertFalse(implAddressV2 == implAddressV1);
    assertEq(newImpl, implAddressV2);
  }
}
