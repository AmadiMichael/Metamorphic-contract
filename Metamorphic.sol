//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./MetamorphicTemplate.sol";

interface Metamorphic {
    function get() external pure returns (uint256);

    // can only be called by Factory
    function kill() external;
}

contract Factory is MetamorphicFactoryTemplate{
    
    // Runtime code breakdown
    /** Opcodes             Mnemonic                        Stack state
     *
     *  6000                (PUSH1 0x00)                    [0x00]
     *  35                  (CALLDATALOAD)                  [(0x00-0x20 0f calldata)]
     *  80                  (DUP1)                          [(0x00-0x20 0f calldata), (0x00-0x20 0f calldata)]
     *  60 e0               (PUSH1 0xe0)                    [0xe0, (0x00-0x20 0f calldata), (0x00-0x20 0f calldata)]
     *  1c                  (SHR)                           [func-sig, (0x00-0x20 0f calldata)]
     *  63 6d4ce63c         (PUSH4 0x6d4ce63c)              [0x6d4ce63c, func-sig, (0x00-0x20 0f calldata)]
     *  14                  (EQ)                            [0/1, (0x00-0x20 0f calldata)]
     *  60 3d               (PUSH1 0x3d)                    [0x3d, 0/1, (0x00-0x20 0f calldata)]
     *  57                  (JUMPI)                         [(0x00-0x20 0f calldata)]
     *  80                  (DUP1)                          [(0x00-0x20 0f calldata), (0x00-0x20 0f calldata)]
     *  60 e0               (PUSH1 0xe0)                    [0xe0, (0x00-0x20 0f calldata), (0x00-0x20 0f calldata)]
     *  1c                  (SHR)                           [func-sig, (0x00-0x20 0f calldata)]
     *  63 41c0e1b5         ((PUSH4 0x41c0e1b5)             [0x41c0e1b5, func-sig, (0x00-0x20 0f calldata)]
     *  14                  (EQ)                            [0/1, (0x00-0x20 0f calldata)]
     *  60 1e               (PUSH1 0x1e)                    [0x1e, 0/1, (0x00-0x20 0f calldata)]
     *  57                  (JUMP1)                         [(0x00-0x20 0f calldata)]
     *  fe                  (INVALID)
     *
     *
     *
     *
     * JUMPDEST: 0x1e
     *  -------------------SELF DESTRUCT FUNCTION-----------------------
     *
     *  5b                  (JUMPDEST)                      []
     *  73 address(this)    (PUSH20 address(this))          [address(this)]
     *  80                  (DUP1)                          [address(this), address(this)]
     *  33                  (CALLER)                        [msg.sender, address(this), address(this)]
     *  14                  (EQ)                            [0/1, address(this)]
     *  60 3b               (PUSH1 0x3b)                    [0x3b, 0/1, address(this)]
     *  57                  (JUMPI)                         [address(this)]
     *  fe                  (INVALID)                       []
     *
     * JUMPDEST: 0x3b
     *  5b                  (JUMPDEST)                      [address(this)]
     *  ff                  (SELFDESTRUCT)                  []
     *
     *
     *
     *
     * JUMPDEST: 0xed
     * -------------------------GET FUNCTION-----------------------------
     *
     *  5b                  (JUMPDEST)                      []
     *
     * implementation: x is the input parsed into `changeRuntimeReturnVal()` below
                       default: 01
     *              60 x    (PUSH1 x)                       [x]
     *
     *  60 00               (PUSH1 0x00)                    [0x00, x]
     *  52                  (MSTORE)                        []
     *  60 20               (PUSH1 0x20)                    [0x20]
     *  60 00               (PUSH1 0x00)                    [0x00, 0x20]
     *  f3                  (RETURN)                        []
     */
    constructor () {
     implementation =
        abi.encodePacked(
            hex"6000358060e01c636d4ce63c14603d578060e01c6341c0e1b514601e57fe5b73",
            address(this),
            hex"803314603b57fe5bff5b600160005260206000f3"
        );
    }

}

