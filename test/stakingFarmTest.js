const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));
let catchRevert = require("./exceptions.js").catchRevert;

const rapid = artifacts.require("RapidToken");
const reward = artifacts.require("RewardToken");
const farm = artifacts.require("StakingFarm");

let rapidInstance 
let rewardInstance 
let farmInstance 
contract("Test",(accounts)=>{
describe("Deployement", async function() {
    it("contracts must be deployed", async function(){
         rapidInstance = await rapid.deployed();
         rewardInstance = await reward.deployed();
         farmInstance = await farm.deployed();
        assert.notEqual(rapidInstance, undefined);
        assert.notEqual(rewardInstance, undefined);
        assert.notEqual(farmInstance, undefined);
    })
})

describe("Mint Rapid Tokens",async function(){
    it("Balance should match", async function(){
        for(var i=0;i<5;i++){
        await rapidInstance.mint(accounts[i+1],2000);
        const bal = await rapidInstance.balanceOf(accounts[i+1]);
        assert.equal(bal.toNumber(),2000);
        }
    })
})

describe("Set farm contract as reward minter",async function(){
    it("address must be farm contract address", async function(){
        await rewardInstance.setFarmContractAddress(farmInstance.address);
        let farmAddress = await rewardInstance.farmContractAddress();
        assert.equal(farmAddress,farmInstance.address);
    })
})
let currentStakingRound
let nextStakingRoundStartTime
let totalStakedTokens
describe("Testing Staking contract --> round 1",async function() {
    it("intial params",async function() {
        currentStakingRound = await farmInstance.currentStakingRound();
        nextStakingRoundStartTime = await farmInstance.nextStakingRoundStartTime();
        totalStakedTokens = await farmInstance.totalStakedTokens();
        assert.equal(currentStakingRound.toNumber(),0);
        assert.equal(nextStakingRoundStartTime.toNumber(),0);
        assert.equal(totalStakedTokens.toNumber(),0);
    })
    it("create new staking round",async function() {
        await farmInstance.newStakingRound();
    })    
    it("round id must be incremented", async function() {
        round = await farmInstance.currentStakingRound();
        assert.equal(round.toNumber(),1);
    })
    it("new round start time must be set", async function() {
        nextStakingRoundStartTime = await farmInstance.nextStakingRoundStartTime();
        let block_number = await web3.eth.getBlockNumber();
        assert.equal(nextStakingRoundStartTime.toNumber(), block_number + 30);
    })
    // it("create new staking round before finishing last round - must fail",async function() {
    //     await farmInstance.newStakingRound();
    // }) 

    it("staking balance must match",async function() {
        for(var i=0;i<5;i++){ 
        await rapidInstance.approve(farmInstance.address,2000,{from:accounts[i+1]});
        await farmInstance.stakeTokens(100 * (i+1),{from:accounts[i+1]});
        let bal = await farmInstance.stakingBalance(accounts[i+1]);
        assert.equal(bal.toNumber(),100 * (i+1));
        }
    })
    it("increase stake for odd numbered accounts",async function() {
        for(var i=0;i<5;i++){ 
            if(i%2==0){
                await farmInstance.stakeTokens(10 * (i+1),{from:accounts[i+1]});
                let bal = await farmInstance.stakingBalance(accounts[i+1]);
                assert.equal(bal.toNumber(),100 * (i+1) + 10 * (i+1));
            }       
        }
    })
    it("staking balance",async function() {
        console.log(`---------Staked amount-----------`)
        for(var i=0;i<5;i++){        
        let bal = await farmInstance.stakingBalance(accounts[i+1]);
        console.log(`${accounts[i+1]} ---> ${bal.toNumber()}`);
        }
        let bal = await farmInstance.totalStakedTokens();
        console.log(`total staked ---> ${bal.toNumber()}`);

        bal = await rewardInstance.balanceOf(farmInstance.address);
        console.log(`total reward tokens to be distributed---> ${bal.toNumber()}`);
    })
    function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    it("issue tokens", async function() {
        await timeout(91000)
        await farmInstance.refundStakeAndIssueReward();
    })
    it("Check reward",async function() {
        console.log(`------------Reward Token Balance-------------`)
        for(var i=0;i<5;i++){        
        let bal = await rewardInstance.balanceOf(accounts[i+1]);
        console.log(`${accounts[i+1]} ---> ${bal.toNumber()}`);
        }
    })
})
describe("Testing Staking contract --> round 2",async function() {
    
    it("create new staking round",async function() {
        await farmInstance.newStakingRound();
    })      

    it("staking balance must match",async function() {
        for(var i=0;i<5;i++){ 
        await rapidInstance.approve(farmInstance.address,2000,{from:accounts[i+1]});
        await farmInstance.stakeTokens(50 * (i+1),{from:accounts[i+1]});
        let bal = await farmInstance.stakingBalance(accounts[i+1]);
        assert.equal(bal.toNumber(),50 * (i+1));
        }
    })
    it("increase stake for odd numbered accounts",async function() {
        for(var i=0;i<5;i++){ 
            if(i%2==1){
                await farmInstance.stakeTokens(5 * (i+1),{from:accounts[i+1]});
                let bal = await farmInstance.stakingBalance(accounts[i+1]);
                assert.equal(bal.toNumber(),50 * (i+1) + 5 * (i+1));
            }       
        }
    })
    it("staking balance",async function() {
        console.log(`---------Staked amount-----------`)
        for(var i=0;i<5;i++){        
        let bal = await farmInstance.stakingBalance(accounts[i+1]);
        console.log(`${accounts[i+1]} ---> ${bal.toNumber()}`);
        }
        let bal = await farmInstance.totalStakedTokens();
        console.log(`total staked ---> ${bal.toNumber()}`);

        bal = await rewardInstance.balanceOf(farmInstance.address);
        console.log(`total reward tokens to be distributed---> ${bal.toNumber()}`);
    })
    function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    it("issue tokens", async function() {
        await timeout(91000)
        await farmInstance.refundStakeAndIssueReward();
    })
    it("Check reward",async function() {
        console.log(`------------Reward Token balance-------------`)
        for(var i=0;i<5;i++){        
        let bal = await rewardInstance.balanceOf(accounts[i+1]);
        console.log(`${accounts[i+1]} ---> ${bal.toNumber()}`);
        }
    })
})
})