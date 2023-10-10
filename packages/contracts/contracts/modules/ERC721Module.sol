// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IERC6551Executable.sol";

import "../interfaces/IPackModule.sol";

contract ERC721Module is IPackModule {
    //
    uint256 public constant CALL_OPERATION = 0; // Only call operations are supported for ERC6551
    uint256 public constant CALL_VALUE = 0; // No value is sent with the call
    struct OnCreateData {
        address tokenAddress;
        uint256 id;
    }

    struct OnRevokeData {
        address tokenAddress;
        uint256 id;
    }

    struct OnClaimData {
        address tokenAddress;
        uint256 id;
    }

    // Lifecycle functions
    function onCreate(
        uint256 tokenId,
        address account,
        bytes calldata additionalData
    ) external payable override {
        // unpack data
        OnCreateData[] memory tokensData = abi.decode(
            additionalData,
            (OnCreateData[])
        );
        // Iterate over the array of TokenData objects
        for (uint256 i = 0; i < tokensData.length; i++) {
            OnCreateData memory tokenData = tokensData[i];

            IERC721(tokenData.tokenAddress).safeTransferFrom(
                msg.sender,
                account,
                tokenData.id
            );
        }
        // TODO: Add more data to the event
        emit Created(tokenId, account);
        return;
    }

    function onOpen(
        uint256 tokenId,
        address account,
        address claimer,
        bytes calldata additionalData
    ) external override {
        // unpack data
        OnClaimData[] memory tokensData = abi.decode(
            additionalData,
            (OnClaimData[])
        );

        // Iterate over the array of TokenData objects
        for (uint256 i = 0; i < tokensData.length; i++) {
            OnClaimData memory tokenData = tokensData[i];

            IERC6551Executable(payable(account)).execute(
                tokenData.tokenAddress,
                CALL_VALUE,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)",
                    account,
                    claimer,
                    tokenData.id
                ),
                CALL_OPERATION
            );
        }
        emit Opened(tokenId, account);
        return;
    }

    function onRevoke(
        uint256 tokenId,
        address account,
        bytes calldata additionalData
    ) external override {
        // unpack data
        OnRevokeData[] memory tokensData = abi.decode(
            additionalData,
            (OnRevokeData[])
        );

        // Iterate over the array of TokenData objects
        for (uint256 i = 0; i < tokensData.length; i++) {
            OnRevokeData memory tokenData = tokensData[i];

            IERC6551Executable(payable(account)).execute(
                tokenData.tokenAddress,
                CALL_VALUE,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)",
                    account,
                    msg.sender,
                    tokenData.id
                ),
                CALL_OPERATION
            );
        }

        emit Revoked(tokenId, account);
        return;
    }
}
