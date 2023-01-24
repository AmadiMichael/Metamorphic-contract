# **Metamorphic Contracts**

Smart contracts are known to be immutable and hence trustless

With create2, selfdestruct and a few tricks. this isn't entirely true.

Create2 to deploy to a deterministic address but remember that the runtime code is whatever is returned at the end of the init code
Usually this is a constant value but what if we program the init code to make a call to a contract we control and use whatever is returned as the runtime code?

That means we can store any value in that contract whenever we want and casually change the bytecode to different runtime codes we wish to.

But there's a catch. The EVM doesn't let us deploy to an address with code in it so this wouldn't work.

### **That's where self destruct comes in...**

We can self destruct the metamorphic contract and then redeploy it to the same address using create2 (because after self destruct the contract is as good as new) and with whatever code we like ⚡️

## **But there's a catch**

Since the contract was self destructed, all storage slots are wiped. Meaning this is terrible for upgradable contracts.
