// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 < 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract CommunityRewards is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private _token;

    struct RewardsInfo {
        address rewardsToken;
        uint256 rewardsAmount;
    }

    struct ReportInfo {
        address token;
        uint256 amount;
    }

    mapping(address => RewardsInfo) public rewardsInfoByToken;

    constructor(IERC20 token) Ownable() public {
        require(address(token) != address(0), "CommunityRewards: token is the zero address");
        _token = token;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @dev upload account rewardsAmount
     * @param rewardsToken the token of rewards
     * @param rewardsAmount the amount of update
     */
    function updateRewardsAmount(address rewardsToken, uint256 rewardsAmount) public onlyOwner {
        // Not is 0x address
        require(rewardsToken != address(0), 'CommunityRewards: reward to the zero address');
        // the rewardsAmount must be gt zero
        require(rewardsAmount > 0, 'CommunityRewards: the balance is zero');

        RewardsInfo storage info = rewardsInfoByToken[rewardsToken];
        if (info.rewardsToken != address(0)) {
            info.rewardsAmount = rewardsAmount;
        } else {
            rewardsInfoByToken[rewardsToken] = RewardsInfo(rewardsToken, rewardsAmount);
        }
    }

    /**
     * @dev upload report to update rewards list data
     * @param list upload data array
     */
    function updateRewardsList(ReportInfo[] memory list) public onlyOwner {
        require(list.length > 0, "CommunityRewards: list array is null");
        for (uint i = 0; i < list.length; i++) {
            ReportInfo memory reportInfo = list[i];
            if (reportInfo.amount > 0) {
                _addRewardsTokens(reportInfo.token, reportInfo.amount);
            }
        }
    }

    /**
     * @dev add rewards list data
     * @param rewardsToken the token of rewards
     * @param rewardsAmount the amount of update
     */
    function _addRewardsTokens(address rewardsToken, uint256 rewardsAmount) internal {
        rewardsAmount = rewardsAmount * (10**uint256(18));
        RewardsInfo storage info = rewardsInfoByToken[rewardsToken];
        if (info.rewardsToken != address(0)) {
            info.rewardsAmount = info.rewardsAmount.add(rewardsAmount);
        } else {
            rewardsInfoByToken[rewardsToken] = RewardsInfo(rewardsToken, rewardsAmount);
        }
    }

    /**
     * @dev admin claim
     * @param rewardsToken the token of rewards
     * @param claimAmount the amount of claim
     */
    function claimByAdmin(address rewardsToken, uint256 claimAmount) public onlyOwner {
        _claim(rewardsToken, claimAmount);
    }

    /**
     * @dev self claim
     * @param claimAmount the amount of claim
     */
    function claim(uint256 claimAmount) public {
        _claim(msg.sender, claimAmount);
    }

    /**
     * @dev common claim function
     * @param rewardsToken the token of rewards
     * @param claimAmount the amount of claim
     */
    function _claim(address rewardsToken, uint256 claimAmount) internal {
        // Not is 0x address
        require(rewardsToken != address(0), 'CommunityRewards: claim from the zero address');
        RewardsInfo storage info = rewardsInfoByToken[rewardsToken];
        // the claimAmount must be gt zero
        require(claimAmount > 0, 'CommunityRewards: the balance is zero');
        // the balance must be gt zero
        require(info.rewardsAmount > 0, 'CommunityRewards: the balance is zero');
        // claimAmount must be lt or equal rewardsAmount
        require(claimAmount <= info.rewardsAmount, 'CommunityRewards: the withdrawal amount exceeds the balance');

        _token.safeTransfer(rewardsToken, claimAmount);
        info.rewardsAmount = info.rewardsAmount.sub(claimAmount);
    }

    function killSelf(address payable recipientToken) public onlyOwner {
        uint256 contractBalance = _token.balanceOf(address(this));
        _token.safeTransfer(recipientToken, contractBalance);

        selfdestruct(recipientToken);
    }
}
