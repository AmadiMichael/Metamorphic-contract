# **Metamorphic Contracts**

    This repo is purely experimental. Do not use in production

Smart contracts are known to be immutable and hence trustless

With create2, selfdestruct and a few tricks. this isn't always the case.

Create2 can be used to deploy to a deterministic address but remember that the runtime code is whatever is returned at the end of the init code.
Usually this is a constant value but what if we program the init code to make a call to a contract we control and use whatever is returned as the runtime code?
That means we can store any value in that contract whenever we want and casually change the bytecode to different runtime codes we wish to.

Using solidity this isn't fully possible as constructors aren't allowed to return values for obvious reasons so we will have to go low level 🫡

There's a catch though. The EVM doesn't let us deploy to an address with code in it so this wouldn't work.

### **That's where self destruct comes in...**

We can self-destruct the metamorphic contract and then redeploy it to the same address using create2 (because after self destruct the contract is as good as new) and with whatever code we like ⚡️

## **Note**

Since the contract was self destructed, all storage slots are wiped. Meaning this is terrible for upgradable contracts.

Metamorphic contracts are mostly used to store and fetch what would be 'immutable' values in a cheaper way over using SLOAD and SSTORE. Our implementation attempts to change the hardcoded return value of the `get()` function. By hardcoded i mean the return value is not reading from a storage slot.

The `get()` function bytecode implementation in solidity would be

```solidity
function get() external view returns(uint256) {
    return 1;
}
```

Deploying this normally would mean `get()` should always return `1` in all circumstances and can never be changed. We use the metamorphic properties of combining create2 and self destruct in a unique way to actually change this hardcoded return value.

# Time to play around with **METAMORPHISM**

This is a simple implementation, the same logic can be applied to different scenarios. But here's an overview of how you can test this out yourself

Open this code up on remix [here](https://remix.ethereum.org/#url=https://github.com/AmadiMichael/Metamorphic-contract/blob/main/Metamorphic.sol&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.17+commit.8df45f5f.js)

- Deploy the Factory contract
- Create the metamorphic contract with a salt of your choice by calling `deployMorph(uint256)`
- Copy the address from the event logs of the transaction or get the address by parsing in the same salt into the `getAddressOfMorph(uint256)` function.
- Load the address up using the Metamorphic Interface. (Change the active contract from Factory to Metamorphic, paste the address in the `At Address` box below it and click on it)
- Click on get in the Metamorphic instance. It should return 1 (thats the default the byte code is hardcoded to return)
- Kill the contract. (calling kill on the Metamorphic instance directly won't work as the EOA of remix isn't the owner rather the owner is the Factory, so call kill on the owner which calls kill on the Metamorphic instance)
- This self destructs the Metamorphic instance and calling get should return 0 and calling kill from the factory should revert as there's no code to call execute (There's a convenience function you can use to track this called `getByte(address)` which returns the bytecode of the address inputted)
- Call `changeRuntimeReturnVal(uint8)` with the new value you want the changed bytecode of Metamorphic to return when calling `get()`.
- Deploy the Metamorphic contract with the same salt
- Call `get()` and see the value return the value you chose.

Now this isn't a particularly interesting application of Metamorphic contracts but it's certainly educational and experimental for those who don't fully understand how it works. This can easily be done/confused with storing a value in storage. Without using `getByte(uint8)` to see the bytecode change it's not much interesting. It gets interesting when it's used in cool ways like [RSA-presale-allowlist](https://github.com/RareSkills/RSA-presale-allowlist) and [SSTORE2](https://github.com/0xsequence/sstore2), this repo was greatly inspired by them.
