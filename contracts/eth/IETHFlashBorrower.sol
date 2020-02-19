pragma solidity 0.5.16;


interface IETHFlashBorrower {
    function executeOnETHFlashLoan(uint256 amount, uint256 debt) external;
}
