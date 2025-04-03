// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.28;

import { SafeERC20, IERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155
}

struct Token {
    TokenType tokenType;
    bytes data;
}

contract EnsoRouter {
    using SafeERC20 for IERC20;

    error WrongValue(uint256 value, uint256 amount);
    error AmountTooLow(Token token);
    error Duplicate();

    // @notice Route a single token via a call to an external contract
    // @param tokenIn The encoded data for the token to send
    // @param target The address of the target contract
    // @param data The call data to be sent to the target
    function routeSingle(
        Token calldata tokenIn,
        address target,
        bytes calldata data
    ) public payable returns (bytes memory response) {
        bool isNativeAsset = _transfer(tokenIn, target);
        if (!isNativeAsset && msg.value != 0) revert WrongValue(msg.value, 0);
        response = _execute(target, msg.value, data);
    }

    // @notice Route multiple tokens via a call to an external contract
    // @param tokensIn The encoded data for the tokens to send
    // @param target The address of the target contract
    // @param data The call data to be sent to the target
    function routeMulti(
        Token[] calldata tokensIn,
        address target,
        bytes calldata data
    ) public payable returns (bytes memory response) {
        uint256 length = tokensIn.length;

        bool isNativeAsset;
        for (uint256 i; i < length; ++i) {
            if (_transfer(tokensIn[i], target)) {
                if (isNativeAsset) revert Duplicate(); // Native asset can only be included once
                isNativeAsset = true;
            }
        }
        if (!isNativeAsset && msg.value != 0) revert WrongValue(msg.value, 0);
        
        response = _execute(target, msg.value, data);
    }

    // @notice Route a single token via a call to an external contract and revert if there is insufficient token received
    // @param tokenIn The encoded data for the token to send
    // @param tokenOut The encoded data for the token to receive
    // @param receiver The address of the wallet that will receive the tokens
    // @param target The address of the target contract
    // @param data The call data to be sent to the target
    function safeRouteSingle(
        Token calldata tokenIn,
        Token calldata tokenOut,
        address receiver,
        address target,
        bytes calldata data
    ) external payable returns (bytes memory response) {
        uint256 balance = _balance(tokenOut, receiver);
        response = routeSingle(tokenIn, target, data);
        _checkMinAmountOut(tokenOut, receiver, balance);
    }

    // @notice Route multiple tokens via a call to an external contract and revert if there is insufficient tokens received
    // @param tokensIn The encoded data for the tokens to send
    // @param tokensOut The encoded data for the tokens to receive
    // @param receiver The address of the wallet that will receive the tokens
    // @param target The address of the target contract
    // @param data The call data to be sent to the target
    function safeRouteMulti(
        Token[] calldata tokensIn,
        Token[] calldata tokensOut,
        address receiver,
        address target,
        bytes calldata data
    ) external payable returns (bytes memory response) {
        uint256 length = tokensOut.length;

        uint256[] memory balances = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            balances[i] = _balance(tokensOut[i], receiver);
        }

        response = routeMulti(tokensIn, target, data);

        for (uint256 i; i < length; ++i) {
            _checkMinAmountOut(tokensOut[i], receiver, balances[i]);
        }
    }

    // @notice A function to execute an arbitrary call on another contract
    // @param target The address of the target contract
    // @param value The ether value that is to be sent with the call
    // @param data The call data to be sent to the target
    function _execute(
        address target,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory response) {
        bool success;
        (success, response) = target.call{value: value}(data);
        if (!success) {
            assembly{
                revert(add(response, 32), mload(response))
            }
        }
    }

    function _transfer(Token calldata token, address receiver) internal returns (bool isNativeAsset) {
        TokenType tokenType = token.tokenType;

        if (tokenType == TokenType.ERC20) {
            (IERC20 erc20, uint256 amount) = abi.decode(token.data, (IERC20, uint256));
            erc20.safeTransferFrom(msg.sender, receiver, amount);
        } else if (tokenType == TokenType.Native) {
            (uint256 amount) = abi.decode(token.data, (uint256));
            if (msg.value != amount) revert WrongValue(msg.value, amount);
            isNativeAsset = true;
        } else if (tokenType == TokenType.ERC721) {
            (IERC721 erc721, uint256 tokenId) = abi.decode(token.data, (IERC721, uint256));
            erc721.safeTransferFrom(msg.sender, receiver, tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            (IERC1155 erc1155, uint256 tokenId, uint256 amount) = abi.decode(token.data, (IERC1155, uint256, uint256));
            erc1155.safeTransferFrom(msg.sender, receiver, tokenId, amount, "0x");
        }
    }

    function _balance(Token calldata token, address receiver) internal view returns (uint256 balance) {
        TokenType tokenType = token.tokenType;

        if (tokenType == TokenType.ERC20) {
            (IERC20 erc20, ) = abi.decode(token.data, (IERC20, uint256));
            balance = erc20.balanceOf(receiver);
        } else if (tokenType == TokenType.Native) {
            balance = receiver.balance;
        } else if (tokenType == TokenType.ERC721) {
            (IERC721 erc721, ) = abi.decode(token.data, (IERC721, uint256));
            balance = erc721.balanceOf(receiver);
        } else if (tokenType == TokenType.ERC1155) {
            (IERC1155 erc1155, uint256 tokenId, ) = abi.decode(token.data, (IERC1155, uint256, uint256));
            balance = erc1155.balanceOf(receiver, tokenId);
        }
    }

    function _checkMinAmountOut(Token calldata token, address receiver, uint256 prevBalance) internal view {
        TokenType tokenType = token.tokenType;

        uint256 balance;
        uint256 minAmountOut;
        if (tokenType == TokenType.ERC20) {
            IERC20 erc20;
            (erc20, minAmountOut) = abi.decode(token.data, (IERC20, uint256));
            balance = erc20.balanceOf(receiver);
        } else if (tokenType == TokenType.Native) {
            (minAmountOut) = abi.decode(token.data, (uint256));
            balance = receiver.balance;
        } else if (tokenType == TokenType.ERC721) {
            IERC721 erc721;
            (erc721, minAmountOut) = abi.decode(token.data, (IERC721, uint256));
            balance = erc721.balanceOf(receiver);
        } else if (tokenType == TokenType.ERC1155) {
            IERC1155 erc1155;
            uint256 tokenId;
            (erc1155, tokenId, minAmountOut) = abi.decode(token.data, (IERC1155, uint256, uint256));
            balance = erc1155.balanceOf(receiver, tokenId);
        }

        uint256 amountOut = balance - prevBalance;
        if (amountOut < minAmountOut) revert AmountTooLow(token);
    }
}
