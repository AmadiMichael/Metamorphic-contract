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
