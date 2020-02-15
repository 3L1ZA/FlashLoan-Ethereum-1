# safer-flash-loans

## Warning

Don't use these contracts in production. They have not yet been audited.

## What is this?

This is a safer, easier, and more flexible flash lending pattern than the current _de facto_ standard.

## How to use it

### Flash lending ERC20 tokens

To add flash lending of ERC20 tokens to your contract, simply inherit the `ERC20FlashLender` contract. Then whitelist whatever ERC20 tokens you want to flash lend.

Example:

```
contract MyContract is ERC20FlashLender {
    // ...
    
    constructor() public {
        _whitelist[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = true; // MKR Token
        _whitelist[0xE41d2489571d322189246DaFA5ebDe1F4699F498] = true; // ZRX Token
        _whitelist[0x0D8775F648430679A709E98d2b0Cb6250d2887EF] = true; // BAT Token
        // ...
    }
    
    // ...
}
```

You can set the interest/fee for borrowing ERC20 tokens by setting the internal `_tokenBorrowFee` variable of the `ERC20FlashLender` contract.

### Flash lending ETH

To add flash lending of ETH to your contract, simply inherit the `ETHFlashLender` contract.

Example:

```
contract MyContract is ETHFlashLender { ... }
```


You can set the interest/fee for borrowing ETH tokens by setting the internal `_ethBorrowFee` variable of the `ETHFlashLender` contract.

### Flash lending both ERC20 tokens and ETH

You can add _both_ ETH and ERC20 flash lending capability to your contract simply by inheriting both contracts, then whitelisting the ERC20 tokens you want to want to lend.

Example:

```
contract MyContract is ERC20FlashLender, ETHFlashLender {
    // ...
    
    constructor() public {
        _whitelist[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = true; // MKR Token
        _whitelist[0xE41d2489571d322189246DaFA5ebDe1F4699F498] = true; // ZRX Token
        _whitelist[0x0D8775F648430679A709E98d2b0Cb6250d2887EF] = true; // BAT Token
        // ...
    }
    
    // ...
}
```


## How is this different from other flash loans?

The current _de facto_  standard flash loan pattern that you see in other projects checks if the loan has been repaid by doing a before/after balance check on the lending contract.

That is, they check the token/ETH balance of the lending contract before the loan, and then check it again after the loan. If the balance after is at least the balance before (plus the required interest) then it is assumed that the loan has been repaid.

In other words, after giving the tokens/ETH to the borrower, the lender contract interprets all further contract balance increases as loan repayments. This is a dangerous assumption, and can result in trivial attacks on the Lender contract _unless the lender contract locks down all other functionality while the flash loan is out_.

So the before/after balance check patterns works, but only if your project locks down all interesting functionality while the borrower has the loan.

This means that users who borrow from you have to take the borrowed money to some other project to use it. This is not ideal.

The safer-flash-loan pattern ensures that an ERC20 loan has been repaid (or else reverts) not by doing a before/after balance check, but instead by _performing the payback itself_. The flash loan function uses ERC20's `transferFrom` function to perform the loan repayment itself -- reverting if the borrower hasn't approved repayment or if the transfer fails. In this way, there is no need to try to indirectly detect whether repayment has occurred, because we're performing the repayment action ourselves. There is no need to give any consideration to the lending contract's balance before or after the loan.

In the case of ETH, there is nothing analogous to ERC20's `transferFrom` function, so the lending contract cannot initiate the loan repayment on behalf of the borrower. Instead, we store the amount of `_ethBorrowerDebt` that the borrower must repay, and we require that the borrower _explicitly_ repay that debt via a `repayEthDebt()` function on the Lender contract. No money sent to the lender contract is treated as a loan repayment unless it comes via the `repayEthDebt()`. And the `repayEthDebt()` simply receives ETH and reduces the `_ethBorrowerDebt` by the amount it receives. This completely removes any ambiguity related to what should be treated as a loan repayment. Instead, we simply check that the `_ethBorrowerDebt` variable is `0` before the transaction completes.

In both cases, the result is that there is no need to lock down the rest of your contracts with reentrancy guards simply for the sake of your flash loans. (Of course, there may be other, unrelated reasons to use reentrances guards in your contracts).

# Security considerations

## For lenders

1. The repayment check relies _entirely_ on the ERC20's `transferFrom` function either reverting or returning `false` if the transfer fails. This behavior is required of ERC20-compliant tokens. However, not all tokens that bill themselves as "ERC20 compliant" are actually compliant with the ERC20 standard. So be sure the token is compliant (at least with this specific behavior of the `transferFrom` function) before you whitelist it.

The risk here is limited. If you whitelist a non-compliant token that may result in your non-compliant token being stolen from the Lender contract. But it cannot be used to steal compliant tokens from your contract.

2.  Flash loans have the effect of temporarily decreasing your contract's balance (both ETH and ERC20 balances). If your contract relies on its ETH/ERC20 contract balances for business logic, then you should be very careful before deciding whether or not to use _any_ flash loans at all (whether this safer-flash-loan pattern, the before/after check pattern, or some other pattern). These safer-flash-loans won't magically make your internal logic safe to use with flash loans generally. Red-flags to look for are any logic that leverages `address(this).balance` or `token.balanceOf(address(this))`.

## For borrowers

1. A malicious flash lender could front-run your flash borrow with an aggressive update to the borrower fee. For example, they could detect your borrow transaction, and then front-run with a fee update that is exactly of the right size to wipe out the entire ETH/token balance of your Borrower contract.

So if the project from which you are taking flash loans has the ability to instantly update the fee they charge, then it would be wise to implement a "fee check" in your Borrower contracts that reverts if the fee is larger than you expect.

This is true for all flash loan patterns.

2. In the example borrower contracts, the lending contract can call the `execute...` function on the borrower contract. A malicious lender contract may call this function even if not initiated by the borrower's `borrow...` function. Keep this in mind use only trusted lender contracts for flash loans. Alternatively, if you are concerned about a possibly malicious flash lender, you may implement a check to be sure that the `execute...` function was called only during the same transaction as the borrower called the `borrow...` function.

This, also, is true for all flash loan patterns.

# Credit where it's due

I discovered the ETH variant of this pattern independently. The first iteration of this pattern used the same "explicit payback function" for ERC20 tokens as for ETH loan repayments. The ERC20 simplification (using `transferFrom` in the flash loan function) is credited to Emilio from Aave -- who in no way is promoting this pattern. If you like it, give credit to Emilio. If you don't like it, blame it on me :).

I have no intention to develop this further. I may update to fix bugs as they are discovered. Please feel free to fork it, own it, and make flash loans easier, safer, and more flexible for everyone. <3
