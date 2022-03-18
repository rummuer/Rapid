//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./RapidToken.sol";
import "./RewardToken.sol";

contract StakingFarm2 {

    RapidToken public rapidToken;
    RewardToken public rewardToken;

    uint constant  numberOfBlocksPerDay = 1; // Estimating Block Generation time as 3 seconds per block
    uint constant stakingDays = 30;

    uint constant stakingPeriod = stakingDays * numberOfBlocksPerDay;
    uint public currentStakingRound = 0;
    uint public currentStakingRoundStartTime = 0;
    uint public nextStakingRoundStartTime = 0;
    uint rewardTokenPerBlock = 10 ;
    uint rewardTokensPerStakingPeriod = rewardTokenPerBlock * stakingPeriod;
    uint public totalStakedTokens = 0;

    address[] public stakers;

    struct stakingBalance {
        uint pendingRewards;
        uint stakedTokens;
        uint toBeCalculatedFrom;
    }
    mapping(address=>stakingBalance) public stakingBalances;
    mapping(address=>bool) public hasStaked;
    mapping(address=>bool) public isStaking;
    mapping(uint=>bool) public isCurrentStakingRoundEnded;

    event staked(address staker, uint amount, uint blockNumber);

    constructor(RapidToken _rapidToken, RewardToken _rewardToken)  {
        rapidToken = _rapidToken;
        rewardToken = _rewardToken;
        isCurrentStakingRoundEnded[currentStakingRound] = true;
    }

    function newStakingRound() public {
        require(isCurrentStakingRoundEnded[currentStakingRound],"Cannot start new staking round before the current one is ended");
        currentStakingRound++;
        rewardToken.mint(address(this), rewardTokensPerStakingPeriod);
        currentStakingRoundStartTime = block.number;
        nextStakingRoundStartTime = block.number + stakingPeriod;
    }

    function stakeTokens(uint _amount) public {
        require(_amount>0, "Staking amount must be greater than 0");
        require(!isCurrentStakingRoundEnded[currentStakingRound],"Cannot stake tokens after the current staking round has ended");
        require(block.number<nextStakingRoundStartTime,"Cannot stake tokens after the staking period");
        rapidToken.transferFrom(msg.sender, address(this), _amount);        
        totalStakedTokens += _amount;
        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }
        else {
            stakingBalances[msg.sender].pendingRewards += 
            stakingBalances[msg.sender].stakedTokens 
            * (block.number-1 - stakingBalances[msg.sender].toBeCalculatedFrom);
        }
        stakingBalances[msg.sender].toBeCalculatedFrom = block.number;
        stakingBalances[msg.sender].stakedTokens += _amount;
        isStaking[msg.sender] = true;
        emit staked(msg.sender, _amount, block.number);
    }

    function refundStakeAndIssueReward() public {
        require(block.number>nextStakingRoundStartTime, "Cannot issue tokens before the current staking round is ended");
        uint totalStakingWeight= getTotalStakingWeight();
        for(uint i=0; i<stakers.length; i++) {
            if(isStaking[stakers[i]]) {
             uint stakerWeight = (stakingBalances[stakers[i]].stakedTokens 
                * (nextStakingRoundStartTime - stakingBalances[stakers[i]].toBeCalculatedFrom))
                 + stakingBalances[stakers[i]].pendingRewards;
                uint reward = stakerWeight * rewardTokensPerStakingPeriod / totalStakingWeight;
             rewardToken.transfer(stakers[i], reward);
             uint balance = stakingBalances[stakers[i]].stakedTokens ;
             rapidToken.transfer(stakers[i], balance);
             stakingBalances[stakers[i]].stakedTokens = 0;
             isStaking[stakers[i]] = false;
            }
         }
        isCurrentStakingRoundEnded[currentStakingRound] = true;
        totalStakedTokens = 0;
    }
    function getTotalStakingWeight() public view returns(uint){
        uint totalStakingWeight = 0;
        for(uint i=0; i<stakers.length; i++) {
            if(isStaking[stakers[i]]) {
                totalStakingWeight += (stakingBalances[stakers[i]].stakedTokens 
                * (nextStakingRoundStartTime - stakingBalances[stakers[i]].toBeCalculatedFrom))
                 + stakingBalances[stakers[i]].pendingRewards;
            }
        }
        return totalStakingWeight;
    }

    

}