//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./RapidToken.sol";
import "./RewardToken.sol";

/* This is a level 1 contract, it will distribute rewards proportional 
to the staking amount irrespective of when the user has 
staked the Rapid Tokens. 
The reward amount per user is calculated as follows:
            
                    (U * X)/N
    
    where U is the amount of Rapid Tokens staked by the user,
     X is the number of reward tokens that have to be distributed in a staking round
    N is the total amount of Rapid Tokens staked by all users
*/


contract StakingFarm {

    RapidToken public rapidToken;
    RewardToken public rewardToken;

    
    //uint constant  numberOfBlocksPerDay = 28800; // Estimating Block Generation time as 3 seconds per block
    //uint constant stakingDays = 30;

    uint constant  numberOfBlocksPerDay = 1; // Estimating Block Generation time as 3 seconds per block
    uint constant stakingDays = 30;

    uint constant stakingPeriod = stakingDays * numberOfBlocksPerDay;
    uint public currentStakingRound = 0;
    uint public nextStakingRoundStartTime = 0;
    uint rewardTokenPerBlock = 10 ;
    uint rewardTokensPerStakingPeriod = rewardTokenPerBlock * stakingPeriod;
    uint public totalStakedTokens = 0;

    address[] public stakers;
    mapping(address=>uint) public stakingBalance;
    mapping(address=>bool) public hasStaked;
    mapping(address=>bool) public isStaking;
    mapping(uint=>bool) public isCurrentStakingRoundEnded;

    constructor(RapidToken _rapidToken, RewardToken _rewardToken)  {
        rapidToken = _rapidToken;
        rewardToken = _rewardToken;
        isCurrentStakingRoundEnded[currentStakingRound] = true;
    }
    function newStakingRound() public {
        require(isCurrentStakingRoundEnded[currentStakingRound],"Cannot start new staking round before the current one is ended");
        currentStakingRound++;
        rewardToken.mint(address(this), rewardTokensPerStakingPeriod);
        nextStakingRoundStartTime = block.number + stakingPeriod;
    }

    function stakeTokens(uint _amount) public  {
        require(_amount>0, "Staking amount must be greater than 0");
        rapidToken.transferFrom(msg.sender, address(this), _amount);        
        stakingBalance[msg.sender] += _amount;
        totalStakedTokens += _amount;
        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }
        isStaking[msg.sender] = true;
    }

    function refundStakeAndIssueReward() public {
        require(block.number>nextStakingRoundStartTime, "Cannot issue tokens before the current staking round is ended");
        for(uint i=0; i<stakers.length; i++) {
            if(isStaking[stakers[i]]) {
             uint reward = (stakingBalance[stakers[i]] * rewardTokensPerStakingPeriod)/totalStakedTokens;
             rewardToken.transfer(stakers[i], reward);
             uint balance = stakingBalance[stakers[i]];
             rapidToken.transfer(stakers[i], balance);
             stakingBalance[stakers[i]] = 0;
             isStaking[stakers[i]] = false;
            }
         }
        isCurrentStakingRoundEnded[currentStakingRound] = true;
        totalStakedTokens = 0;
    }
}