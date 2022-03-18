//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./RapidToken.sol";
import "./RewardToken.sol";

contract StakingFarm3 {

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
        uint toBeCalculatedTill;
        uint reward;
        uint stakingWeight;
        bool isWithdrawn;
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

    function deposit(uint _amount) public {
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
    function withDraw() public {
        require(!stakingBalances[msg.sender].isWithdrawn,"Already Withdrawn");
        uint balance = stakingBalances[msg.sender].stakedTokens ;
        rapidToken.transfer(msg.sender, balance); 
        stakingBalances[msg.sender].toBeCalculatedTill = block.number;
        stakingBalances[msg.sender].isWithdrawn = true;
    }
    function claim() public {
        require(isCurrentStakingRoundEnded[currentStakingRound],"Cannot claim rewards before the current staking round has ended");
        require(!isStaking[msg.sender],"Cannot claim rewards while staking");
        rewardToken.transfer(msg.sender, stakingBalances[msg.sender].reward);
        stakingBalances[msg.sender].reward = 0;
    }

    function endStakingRound() public {
        require(block.number>nextStakingRoundStartTime, "Cannot end before the current staking round is ended");
        require(!isCurrentStakingRoundEnded[currentStakingRound],"Cannot end the current staking round twice");
        isCurrentStakingRoundEnded[currentStakingRound] = true;
        uint totalStakingWeight = getTotalStakingWeight();
        for(uint i=0;i<stakers.length;i++){
            uint stakingWeight = stakingBalances[stakers[i]].stakingWeight;
            uint reward = (rewardTokensPerStakingPeriod * stakingWeight) / totalStakingWeight;
            stakingBalances[stakers[i]].reward = reward;
        }
    }

    function getTotalStakingWeight() private returns(uint){
        uint totalStakingWeight = 0;
        for(uint i=0; i<stakers.length; i++) {
            if(isStaking[stakers[i]]) {
                if(stakingBalances[stakers[i]].toBeCalculatedTill == 0) {
                stakingBalances[stakers[i]].stakingWeight = (stakingBalances[stakers[i]].stakedTokens 
                * (nextStakingRoundStartTime - stakingBalances[stakers[i]].toBeCalculatedFrom))
                 + stakingBalances[stakers[i]].pendingRewards;
                    totalStakingWeight += stakingBalances[stakers[i]].stakingWeight;
                }
                else {
                    stakingBalances[stakers[i]].stakingWeight = (stakingBalances[stakers[i]].stakedTokens 
                * (stakingBalances[stakers[i]].toBeCalculatedTill - stakingBalances[stakers[i]].toBeCalculatedFrom))
                 + stakingBalances[stakers[i]].pendingRewards;
                    totalStakingWeight += stakingBalances[stakers[i]].stakingWeight;
                }
                 isStaking[stakers[i]] = false;
                 stakingBalances[stakers[i]].stakedTokens = 0;
            }
        }
        return totalStakingWeight;
    }
    
}