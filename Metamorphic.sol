//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface Metamorphic {
    function get() external pure returns (uint256);

    // can only be called by Factory
    function kill() external;
}

contract Factory {
    event Deployed(address addr, uint256 salt);

    // Creation code breakdown
    /** Opcodes                                     Stack state
     *
     * comment: 0x0000000e - function sig of `callback19F236F3()`
     *   63 0000000e (PUSH4 0x0000000e)              [0x0000000e]
     *   60 00       (PUSH1 0x00)                    [0x00, 0x0000000e]
     *   52          (MSTORE)                        []
     *
     * comment: 0x88 - return data from reentrant staticcall is 0x48 bytes + 0x40 bytes for offset and length of return data
     *   60 88       (PUSH1 0x88)                    [0x88]
     *   60 00       (PUSH1 0x00)                    [0x00, 0x88]
     *   60 04       (PUSH1 0x04)                    [0x04, 0x00, 0x88]
     *   60 1c       (PUSH1 0x1c)                    [0x1c, 0x04, 0x00, 0x88]
     *   33          (CALLER)                        [msg.sender, 0x1c, 0x04, 0x00, 0x88]
     *   5a          (GAS)                           [gasleft, msg.sender, 0x1c, 0x04, 0x00, 0x88]
     *   fa          (STATICCALL)                    []
     *
     * comment: 0x48 - length of runtime code alone
     *   60 48       (PUSH1 0x48)                    [0x48]
     *   60 40       (PUSH1 0x40)                    [0x40, 0x48]
     *   f3          (RETURN)                        []
     */

    bytes creationCode = hex"630000000e600052608860006004601c335afa60486040f3";

    // note: the assembly block here works considering that the creation code is 31 bytes or less.
    // dynamic values are only stored in its slot as long as it's 31 bytes or less. the 32nd byte stores (the length * 2),
    // otherwise just ((the length * 2) + 1) is stored at the slot. the value is stored at keccak256(slot).
    function deployMorph(uint256 _salt) external returns (address addr) {
        assembly {
            let val := sload(creationCode.slot)
            mstore(0x80, 0x20)
            mstore(0xa0, div(and(0xff, val), 2))
            mstore(
                0xc0,
                and(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00,
                    val
                )
            )
            addr := create2(0, 0xc0, mload(0xa0), _salt)
        }
        require(addr != address(0));
        emit Deployed(addr, _salt);
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddressOfMorph(uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(creationCode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

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

    bytes implementation =
        abi.encodePacked(
            hex"6000358060e01c636d4ce63c14603d578060e01c6341c0e1b514601e57fe5b73",
            address(this),
            hex"803314603b57fe5bff5b600160005260206000f3"
        );

    // morph calls back into factory to call this function which returns the runtime code based on is1
    function callback19F236F3() external view returns (bytes memory) {
        return implementation;
    }

    // changes what `get()` returns
    // uint8 because 60 (PUSH1) is hardcoded and has a max value of 0xff (255)
    function changeRuntimeReturnVal(uint8 x) external {
        implementation = abi.encodePacked(
            hex"6000358060e01c636d4ce63c14603d578060e01c6341c0e1b514601e57fe5b73",
            address(this),
            hex"803314603b57fe5bff5b60",
            x,
            hex"60005260206000f3"
        );
    }

    // this must be called before redeploying a morph
    function kill(address a) external {
        Metamorphic(a).kill();
    }

    // convenience to check the runtime code of an address to know if the morph's code changed
    function getByte(address addr) external view returns (bytes memory) {
        return addr.code;
    }
}
