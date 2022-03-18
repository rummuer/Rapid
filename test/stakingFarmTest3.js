const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));

const rapid = artifacts.require("RapidToken");
const reward = artifacts.require("RewardToken");
const farm3 = artifacts.require("StakingFarm3");

let rapidInstance 
let rewardInstance 
let farmInstance 
contract("Test",(accounts)=>{
describe("Deployement", async function() {
    it("contracts must be deployed", async function(){
         rapidInstance = await rapid.deployed();
         rewardInstance = await reward.deployed();
         farmInstance = await farm3.deployed();
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
describe("Testing Staking contract --> round 1",async function() {
    
    it("create new staking round",async function() {
        await farmInstance.newStakingRound();
        console.log(`Staking start time is ${await farmInstance.currentStakingRoundStartTime()}`);
        console.log(`Staking end time is ${await farmInstance.nextStakingRoundStartTime()}`);
    })        

    it("stake",async function() {
        for(var i=0;i<5;i++){ 
        await rapidInstance.approve(farmInstance.address,2000,{from:accounts[i+1]});
        let r = await farmInstance.deposit(100 * (i+1),{from:accounts[i+1]});
        //console.log(r.logs[0].args.staker, r.logs[0].args.amount.toNumber(), r.logs[0].args.blockNumber.toNumber());
        console.log(`Account ${r.logs[0].args.staker} staked ${r.logs[0].args.amount.toNumber()} tokens at block ${ r.logs[0].args.blockNumber.toNumber()}`);
        }
    })
    it("increase stake for odd numbered accounts",async function() {
        for(var i=0;i<5;i++){ 
            if(i%2==0){
              let r =  await farmInstance.deposit(10 * (i+1),{from:accounts[i+1]});
              console.log(`Account ${r.logs[0].args.staker} staked ${r.logs[0].args.amount.toNumber()} tokens at block ${ r.logs[0].args.blockNumber.toNumber()}`);
            }       
        }
    })

    it("Withdraw stake account2",async function() {
        await timeout(3000)
        let r = await farmInstance.withDraw({from:accounts[2]});
    })
    it("Withdraw stake account5",async function() {
        await timeout(6000)
        let r = await farmInstance.withDraw({from:accounts[5]});
    })
    
    function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
   
    it("End Staking Round", async function() {
        await timeout(91000)
        await farmInstance.endStakingRound();
    })
    it("Claim reward",async function() {
        for(var i=0;i<5;i++){        
         await farmInstance.claim({from:accounts[i+1]});        
        }
    })

    it("Check reward",async function() {
        console.log(`------------Reward Token Balance-------------`)
        for(var i=0;i<5;i++){        
        let bal = await rewardInstance.balanceOf(accounts[i+1]);
        console.log(`${accounts[i+1]} ---> ${bal.toNumber()}`);
        }
    })
})
})