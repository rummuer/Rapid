# Problem statement
    Write a smart contract to distribute  N ERC-20 (reward) token in X number of days. (Rate should be defined per block e.g  N / (X* (number of Blocks per Day)). 

    The reward token will only be received by the people who have staked another token named rapid token in a contract called  a farm contract. 

# Solution
 I have written the solutions to the problem as follows:

 ## Solution 1 - StakingFarm.sol

 In this solution, the contract will distribute rewards proportional 
 to the staking amount irrespective of when the user has 
 staked the Rapid Tokens. 
 The reward amount per user is calculated as follows:
            
                    $(U * X)/N$
    
    where $U$ is the amount of Rapid Tokens staked by the user,
     $X$ is the number of reward tokens that have to be distributed in a staking round
    $N$ is the total amount of Rapid Tokens staked by all users

### Output screen shots

## Solution 2 - StakingFarm2.sol

In this solution, the contract will distribute the rewards proportional to the staking weight. The staking weight is calculated from the amount the user has staked and the time when the user has staked.

The reward per user is calculated as follows:
                $(U_{weight} * X)/T_{weight}$
    where $U_{weight}$ is the staking weight of the user. It is calculated as
                    $A * M$
    where $A$ is the amount of tokens staked by the user and $M$ is the number of blocks the user has staked that amount. $X$ is the number of reward tokens that have to be distributed in a staking round. $T_{weight}$ is the cummulative staking weight of all the users.