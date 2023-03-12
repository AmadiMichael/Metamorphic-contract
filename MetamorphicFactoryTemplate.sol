//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


contract MetamorphicFactoryTemplate {
    event Deployed(address addr, uint256 salt);

    // Creation code breakdown
    /** Opcodes                                     Stack state
     *
     * comment: 0x0000000e - function sig of `callback19F236F3()`. Store this in memory
     *   60 0e       (PUSH1 0x0e)                     [0x0000000e]
     *   60 e0       (PUSH1 0xe0)                     [0xe0, 0x0e]
     *   1b          (SHL)                            [0x0000000e00000000000000000000000000000000000000000000000000000000]
     *   3d          (RETURNDATASIZE)                 [0x00, 0x0000000e00000000000000000000000000000000000000000000000000000000]
     *   52          (MSTORE)                         []
     *
     * comment: CALL BACK INTO DEPLOYING CONTRACT TO GET THE RUNTIME CODE
     *   3d          (RETURNDATASIZE)                 [0x00]
     *   3d          (RETURNDATASIZE)                 [0x00, 0x00]
     *   60 04       (PUSH1 0x04)                     [0x04, 0x00, 0x00]
     *   3d          (RETURNDATASIZE)                 [0x00, 0x04, 0x00, 0x00]
     *   33          (CALLER)                         [msg.sender, 0x00, 0x04, 0x00, 0x00]
     *   5a          (GAS)                            [gasleft, msg.sender, 0x00, 0x04, 0x00, 0x00]
     *   fa          (STATICCALL)                     [0x01/0x00]
     *
     * comment: REVERT IF STATIC CALL FAILED
     *   60 16       (PUSH1 0x16)                     [0x16, 0x01/0x00]
     *   57          (JUMPI)                          []
     *   60 00       (PUSH1 0x00)                     [0x00]
     *   80          (DUP1)                           [0x00, 0x00]
     *   fd          (REVERT)                         []
     *
     * comment: COPY RUNTIME CODE INTO MEMORY (THIS IS JUMPDEST `0x16`)
     *   5b          (JUMPDEST)                       []
     *   60 40       (PUSH1 0x40)                     [0x40]
     *   3d          (RETURNDATASIZE)                 [RETURNDATASIZE, 0x40]
     *   03          (SUB)                            [LENGTH]
     *   80          (DUP1)                           [LENGTH, LENGTH]
     *   60 40       (PUSH1 0x40)                     [0x40, LENGTH, LENGTH]
     *   60 00       (PUSH1 0x00)                     [0x00, 0x40, LENGTH, LENGTH]
     *   3e          (RETURNDATACOPY)                 [LENGTH]
     *   
     * comment: RETURN RUNTIME CODE FROM MEMORY
     *   60 00       (PUSH1 0x00)                     [0x00, LENGTH]
     *   f3          (RETURN)                         []
     */

    bytes constant private INIT_CODE = hex"600e60e01b3d52_3d3d60043d335afa_601657600080fd_5b60403d0380604060003e_6000f3";

    // note: the assembly block here works considering that the creation code is 31 bytes or less.
    // dynamic values are only stored in its slot as long as it's 31 bytes or less. the 32nd byte stores (the length * 2),
    // otherwise just ((the length * 2) + 1) is stored at the slot. the value is stored at keccak256(slot).
    function deploy(uint256 salt) public returns(address addr){
        bytes memory initCode = INIT_CODE;
        assembly {
            addr := create2(0x00, add(initCode, 0x20), mload(initCode), salt)
        }
        if(addr == address(0)) revert("Create2 failed");
        emit Deployed(addr, salt);
    }
        
    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddressOfMorph(uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(INIT_CODE)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    bytes implementation;

    // morph calls back into factory to call this function which returns the runtime code based on is1
    function callback19F236F3() external view returns (bytes memory) {
        return implementation;
    }

    // changes what `get()` returns
    // uint8 because 60 (PUSH1) is hardcoded and has a max value of 0xff (255)
    function changeRuntimeReturnVal(bytes memory runtime) external {
        implementation = runtime;
    }

    // this must be called before redeploying a morph
    function kill(address a) external {
        (bool success, ) = a.call(abi.encodeWithSignature("kill()"));
        require(success,"kill failed");
    }

    // convenience to check the runtime code of an address to know if the morph's code changed
    function getByte(address addr) external view returns (bytes memory) {
        return addr.code;
    }
}

