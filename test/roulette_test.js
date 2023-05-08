const Roulette = artifacts.require("Roulette")
const Leaderboard = artifacts.require("Leaderboard")


contract("Roulette", (accounts) => {
    let rouletteInstance
    let leaderboardInstance

    let amountT
    let numberT
    let totalBalance
    let winningNumber
    let winners = []
    let gamblers = []

    before(async () => {
        leaderboardInstance = await Leaderboard.deployed()
        rouletteInstance = await Roulette.deployed()
        await rouletteInstance.startBets(leaderboardInstance.address)
    })

    describe("Betting...", function() {

        it("shouldn't allow placing a bet on a number that is not part of roulette", async ()=> {
            
            let number = Math.floor(Math.random() * 36) + 36
            let amount = Math.floor(Math.random() * 1000) + 1
            try{
                await rouletteInstance.bet(number,amount)
            } catch(error) {
                assert.include(error.message,"revert","El mensaje debería contener revert")
            }
        })

        it("shouldn't allow placing a bet equal to 0", async ()=> {
            
            let number = Math.floor(Math.random() * 36)
            let amount = 0
            try{
                await rouletteInstance.bet(number,amount)
            } catch(error) {
                assert.include(error.message,"revert","El mensaje debería contener revert")
            }
        })

        it("should allow betting", async ()=> {
            let number = Math.floor(Math.random() * 36)
            let amount = Math.floor(Math.random() * 1000) + 1
            amountT = amount
            numberT = number
            totalBalance += amount
            gamblers.push(accounts[0])
            await rouletteInstance.bet(number,amount)
        })

        it("shouldn't allow more than one bet", async ()=> {
            let number = Math.floor(Math.random() * 36)
            let amount = Math.floor(Math.random() * 1000) + 1
            try{
                await rouletteInstance.bet(number,amount)
            } catch(error) {
                assert.include(error.message,"revert","El mensaje debería contener revert")
            }
        })

        it("should let me see my bet", async ()=> {
            betTemp = await rouletteInstance.checkMyBet()
            assert.equal(betTemp.betNumber, numberT, "La apuesta mostrada no es la correcta")
            assert.equal(betTemp.betAmount, amountT, "La apuesta mostrada no es la correcta")
        })

        it("should allow betting for someone", async ()=> {
            const Web3 = require('web3');
            const web3 = new Web3(Web3.givenProvider || 'http://localhost:8545');
            
            for (let index = 0; index < 36; index++) {
                let number = index
                let amount = Math.floor(Math.random() * 1000) + 1
                totalBalance += amount
                let address = web3.eth.accounts.create().address
                winners.push(address)
                gamblers.push(address)
                await rouletteInstance.betFor(number,amount, address)
            }
    
        })
        
    })
    describe("End Betting...", function() {
        it("should allow betting time to end and generate a winning number", async ()=> {
            let seed = Math.floor(Math.random() * 1000)
            await rouletteInstance.endBets(seed)
        })
        it("should show the winning number", async ()=> {
            winningNumber = await rouletteInstance.showNumber()
        })
        it("should show the winners", async ()=> {
            let _winners = await rouletteInstance.showTheWinners()
            assert.equal(_winners[0], winners[winningNumber], "Debería mostrar a los ganadores")
        })
        it("should show the gamblers", async ()=> {
            let _gamblers = await rouletteInstance.showGamblers()
            for (let index = 0; index < gamblers.length; index++) {
                assert.equal(_gamblers[index], gamblers[index], "Debería mostrar a los ganadores")
            }
        })
    })
    
})