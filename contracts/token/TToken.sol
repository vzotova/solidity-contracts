// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


/**
* @title TToken
* @notice ERC20 token
*/
contract TToken is ERC20('T', 'T') {
    using SafeERC20 for IERC20;
    
    IERC20 public immutable keepToken;
    IERC20 public immutable nuToken;

    uint256 immutable keepWeightNumerator;
    uint256 immutable keepWeightDenominator;
    uint256 immutable nuWeightNumerator;
    uint256 immutable nuWeightDenominator;

    mapping (address => uint256) wrappedNU;
    mapping (address => uint256) wrappedKeep;

    /**
     * @param _keepToken Address of Keep token contract
     * @param _nuToken Address of NuCypher token contract
     * @param _keepWeightNumerator Numerator for Keep weight calculation
     * @param _keepWeightDenominator Denominator for Keep weight calculation
     * @param _nuWeightNumerator Numerator for NuCypher weight calculation
     * @param _nuWeightDenominator Denominator for NuCypher weight calculation
     */
    constructor(
        IERC20 _keepToken, 
        IERC20 _nuToken,
        uint256 _keepWeightNumerator,
        uint256 _keepWeightDenominator,
        uint256 _nuWeightNumerator,
        uint256 _nuWeightDenominator
    ) {
        // TODO check contracts and input variables
        keepToken = _keepToken;
        nuToken = _nuToken;
        keepWeightNumerator = _keepWeightNumerator;
        keepWeightDenominator = _keepWeightDenominator;
        nuWeightNumerator = _nuWeightNumerator;
        nuWeightDenominator = _nuWeightDenominator;
    }

    /**
     * @notice Recalculates NuCypher tokens to T tokens
     */
    function nuToT(uint256 _amount) public view returns (uint256) {
        return _amount * nuWeightNumerator / nuWeightDenominator;
    }

    /**
     * @notice Recalculates T tokens to NuCypher tokens
     */
    function tToNU(uint256 _amount) public view returns (uint256) {
        return _amount * nuWeightDenominator / nuWeightNumerator;
    }

    /**
     * @notice Recalculates Keep tokens to T tokens
     */
    function keepToT(uint256 _amount) public view returns (uint256) {
        return _amount * keepWeightNumerator / keepWeightDenominator;
    }

    /**
     * @notice Recalculates T tokens to Keep tokens
     */
    function tToKeep(uint256 _amount) public view returns (uint256) {
        return _amount * keepWeightDenominator / keepWeightNumerator;
    }

    /**
     * @notice Wrap NuCypher tokens to T tokens
     */
    function wrapNU(uint256 _nuAmount) external returns (uint256) {
        nuToken.safeTransferFrom(msg.sender, address(this), _nuAmount);
        wrappedNU[msg.sender] += _nuAmount;
        uint256 tAmount = nuToT(_nuAmount);
        require(transfer(msg.sender, tAmount));
        return tAmount;
    }

    /**
     * @notice Wrap Keep tokens to T tokens
     */
    function wrapKeep(uint256 _keepAmount) external returns (uint256) {
        keepToken.safeTransferFrom(msg.sender, address(this), _keepAmount);
        wrappedKeep[msg.sender] += _keepAmount;
        uint256 tAmount = keepToT(_keepAmount);
        require(transfer(msg.sender, tAmount));
        return tAmount;
    }

    /**
     * @notice Unwrap T tokens to NuCypher tokens (if wrapped before)
     */
    function unwrapNU(uint256 _tAmount) external returns (uint256) {
        uint256 nuAmount = tToNU(_tAmount);
        require(nuAmount <= wrappedNU[msg.sender]);
        wrappedNU[msg.sender] -= nuAmount;
        require(transferFrom(msg.sender, address(this), _tAmount));
        nuToken.safeTransfer(msg.sender, nuAmount);
        return nuAmount;
    }

    /**
     * @notice Unwrap T tokens to Keep tokens (if wrapped before)
     */
    function unwrapKeep(uint256 _tAmount) external returns (uint256) {
        uint256 keepAmount = tToKeep(_tAmount);
        require(keepAmount <= wrappedKeep[msg.sender]);
        wrappedKeep[msg.sender] -= keepAmount;
        require(transferFrom(msg.sender, address(this), _tAmount));
        keepToken.safeTransfer(msg.sender, keepAmount);
        return keepAmount;
    }

}
