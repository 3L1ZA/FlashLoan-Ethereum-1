pragma solidity 0.5.16;

import "./ERC20FlashLender.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/token/ERC20/IERC20.sol";

// @notice Used by borrower to flash-borrow ERC20 tokens from ERC20FlashLender
// @dev Example contract. Do not use. Has not been audited.
contract ERC20FlashBorrower is Ownable {

    // set the Lender contract address to a trusted ERC20FlashLender
    ERC20FlashLender public constant erc20FlashLender = ERC20FlashLender(address(0x0));

    // @notice Borrow any ERC20 token that the ERC20FlashLender holds
    function borrow(address token, uint256 amount) public onlyOwner {
        erc20FlashLender.ERC20FlashLoan(token, amount);
    }

    // this is called by ERC20FlashLender after borrower has received the tokens
    // every ERC20FlashBorrower must implement an `executeOnERC20FlashLoan()` function.
    function executeOnERC20FlashLoan(address token, uint256 amount, uint256 debt) external {
        require(msg.sender == address(erc20FlashLender), "only lender can execute");

        //... do whatever you want with the tokens
        //...

        // authorize loan repayment
        IERC20(token).approve(address(erc20FlashLender), debt);
    }
}
