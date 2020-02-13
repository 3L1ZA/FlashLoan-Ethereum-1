pragma solidity 0.5.16;


import "./IETHFlashBorrower.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/utils/ReentrancyGuard.sol";


// @notice Any contract that inherits this contract becomes a flash lender of any/all ETH that it holds
// @dev DO NOT USE. This is has not been audited.
contract ETHFlashLender is ReentrancyGuard {
    using SafeMath for uint256;

    // should never be changed by inheriting contracts
    uint256 private _ethBorrowerDebt;

    // internal vars -- okay for inheriting contracts to change
    uint256 internal _ethBorrowFee; // e.g.: 0.003e18 means 0.3% fee

    uint256 constant internal ONE = 1e18;

    // @notice Borrow ETH via a flash loan. See ETHFlashBorrower for example.
    // @audit Necessarily violates checks-effects-interactions pattern.
    // @audit The `nonReentrant` modifier is critical here.
    function ETHFlashLoan(uint256 amount) external nonReentrant {

        // record debt
        _ethBorrowerDebt = amount.mul(ONE.add(_ethBorrowFee)).div(ONE);

        // send borrower the tokens
        msg.sender.transfer(amount);

        // hand over control to borrower
        IETHFlashBorrower(msg.sender).executeOnETHFlashLoan(amount, _ethBorrowerDebt);

        // check that debt was fully repaid
        require(_ethBorrowerDebt == 0, "loan not paid back");
    }

    // @notice Repay all or part of the loan
    function repayEthDebt() public payable {
        _ethBorrowerDebt = _ethBorrowerDebt.sub(msg.value); // does not allow overpayment
    }


    function ethBorrowerDebt() public view returns (uint256) {
        return _ethBorrowerDebt;
    }
    
    function ethBorrowFee() public view returns (uint256) {
        return _ethBorrowFee;
    }
}
