/**
 *Submitted for verification at BscScan.com on 2024-01-01
*/

/*
  Name: Groks Twin
  Symbol: GroksTwin
  Decimals: 9
  Total supply: 80,000,000
  Network: BSC

  Developed by Immykhan92                             

 SPDX-License-Identifier: MIT */

pragma solidity 0.8.19;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal returns(bool){
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        return success; 
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public tradingPairs;


    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mintOnce(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract GroksTwin is ERC20, Ownable {
    using Address for address payable;

    function addTradingPair(address _pair) external onlyOwner {
        tradingPairs[_pair] = true; 
    }
 function removeTradingPair(address pair) external onlyOwner {
    tradingPairs[pair] = false;
}
    address public feeReceiverBUSD;
    address public feeReceiverUSDT;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFees;

    uint256 public  feeOnBuy;
    uint256 public  feeOnSell;

    uint256 public  feeOnTransfer;

    address public  feeReceiver;

    uint256 public  swapTokensAtAmount;
    bool    private swapping;

    bool    public swapEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndSendFee(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    constructor () ERC20("Groks Twin", "GroksTwin") 
    {   
      address _defaultFeeReceiver = address(0xed2Dae376AcF78C34dC2269A51bB58556e6Dfbf0); // Set the default fee receiver address here
    require(_defaultFeeReceiver != address(0), "Invalid default receiver");
    defaultFeeReceiver = _defaultFeeReceiver;
    feeReceiver = _defaultFeeReceiver;
        address router;
        address pinkLock;
        
        if (block.chainid == 56) {
            router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
            pinkLock = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE; // BSC PinkLock
        } else if (block.chainid == 97) {
            router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Pancake Testnet Router
            pinkLock = 0x5E5b9bE5fd939c578ABE5800a90C566eeEbA44a5; // BSC Testnet PinkLock
        } else if (block.chainid == 1 || block.chainid == 5) {
            router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet % Testnet
            pinkLock = 0x71B5759d73262FBb223956913ecF4ecC51057641; // ETH PinkLock
        } else {
            revert();
        }

        transferOwnership(0xF5b8b375b86D852B9C92fa8F4881cc7eC54A8a19);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        feeOnBuy  = 5;
        feeOnSell = 5;

        feeOnTransfer = 5;

        feeReceiver = 0xed2Dae376AcF78C34dC2269A51bB58556e6Dfbf0;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[pinkLock] = true;

        _mintOnce(owner(), 80_000_000 * (10 ** decimals()));
        swapTokensAtAmount = totalSupply() / 5_000;

        swapEnabled = false;
    }

    receive() external payable {}

    function creator() public pure returns (string memory) {
        return "https://github.com/Immykhan92";
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "CSLT: Owner cannot claim contract's balance of its own tokens");
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
            return;
        }
        
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    event UpdateFees(uint256 feeOnBuy, uint256 feeOnSell);

    function updateFees(uint256 _feeOnSell, uint256 _feeOnBuy, uint256 _feeOnTransfer) external onlyOwner {
        feeOnBuy = _feeOnBuy;
        feeOnSell = _feeOnSell;
        feeOnTransfer = _feeOnTransfer;

        require(feeOnBuy <= 9, "CSLT: Total Fees cannot exceed the maximum");
        require(feeOnSell <= 9, "CSLT: Total Fees cannot exceed the maximum");
        require(feeOnTransfer <= 6, "CSLT: Total Fees cannot exceed the maximum");

        emit UpdateFees(feeOnSell, feeOnBuy);
    }
    
    function setFeeReceiverBUSD(address _feeReceiver) external onlyOwner {
    feeReceiverBUSD = _feeReceiver;
}

function setFeeReceiverUSDT(address _feeReceiver) external onlyOwner {
    feeReceiverUSDT = _feeReceiver;
}

    event FeeReceiverChanged(address feeReceiver);

   
address public immutable defaultFeeReceiver;  // Hardcoded default receiver address
bool public canChangeFeeReceiver = true;     // Flag to control if the receiver can be changed

function changeFeeReceiver(address _feeReceiver) external onlyOwner {
    require(canChangeFeeReceiver, "Changing receiver is disabled");
    require(_feeReceiver != address(0), "CSLT: Fee receiver cannot be the zero address");
    
    // Additional check to ensure the address is likely an EOA or a payable contract
    (bool success,) = _feeReceiver.call{value: 1 wei}("");
    require(success, "CSLT: Receiver must accept BNB");

    // Set the new receiver and emit an event
    feeReceiver = _feeReceiver;
    emit FeeReceiverChanged(feeReceiver);
}

function disableChangingFeeReceiver() external onlyOwner {
    // Once called, the fee receiver can no longer be changed
    canChangeFeeReceiver = false;
}
    
    event TradingEnabled(bool tradingEnabled);

    bool public tradingEnabled;

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "CSLT: Trading already enabled.");
        tradingEnabled = true;
        swapEnabled = true;

        emit TradingEnabled(tradingEnabled);
    }

    function _transfer(address from,address to,uint256 amount) internal  override {
        
        require(from != address(0), "CSLT: transfer from the zero address");
        require(to != address(0), "CSLT: transfer to the zero address");
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "CSLT: Trading not yet enabled!");
       
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            to == uniswapV2Pair &&
            feeOnBuy + feeOnSell > 0 &&
            !_isExcludedFromFees[from] &&
            swapEnabled
        ) {
            swapping = true;

            swapAndSendFee(contractTokenBalance);     

            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
    _totalFees = 0;
} else if (from == uniswapV2Pair) {
    _totalFees = feeOnBuy;
    feeReceiver = feeReceiverBUSD; // Use the fee receiver for the GroksTwin/BUSD pair
} else if (to == uniswapV2Pair) {
    _totalFees = feeOnSell;
    feeReceiver = feeReceiverBUSD; // Use the fee receiver for the GroksTwin/BUSD pair
} else {
    _totalFees = feeOnTransfer;
    feeReceiver = feeReceiverUSDT; // Use the fee receiver for the GroksTwin/USDT pair
}

if (tradingPairs[from] || tradingPairs[to]) {
    _totalFees = (from == uniswapV2Pair || to == uniswapV2Pair) ? feeOnBuy : feeOnTransfer;
    feeReceiver = tradingPairs[from] ? feeReceiverBUSD : feeReceiverUSDT; // Use the appropriate fee receiver based on the trading pair
}
if (_totalFees > 0) {
    uint256 fees = (amount * _totalFees) / 100;
    amount = amount - fees;
    super._transfer(from, address(this), fees);

    // Send fees to the selected fee receiver
    if (feeReceiver != address(0)) {
        super._transfer(address(this), feeReceiver, fees);
    }
}

        super._transfer(from, to, amount);
    }

    function setSwapTokensAtAmount(uint256 newAmount, bool _swapEnabled) external onlyOwner {
        require(newAmount > totalSupply() / 1_000_000, "CSLT: SwapTokensAtAmount must be greater than 0.0001% of total supply");
        swapTokensAtAmount = newAmount;
        swapEnabled = _swapEnabled;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function swapAndSendFee(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        uint256 newBalance = address(this).balance - initialBalance;

        payable(feeReceiver).sendValue(newBalance);

        emit SwapAndSendFee(tokenAmount, newBalance);
    }
}
