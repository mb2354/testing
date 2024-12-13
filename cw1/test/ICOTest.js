// Import Hardhat test environment
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("VehicleRentalICO Contract", function () {
    let VehicleRentalToken, token;
    let VehicleRentalICO, ico;
    let owner, buyer;

    const TOKEN_PRICE = ethers.utils.parseEther("1");
    const INITIAL_SUPPLY = 1000;

    beforeEach(async function () {
        // Deploy VehicleRentalToken contract
        VehicleRentalToken = await ethers.getContractFactory("VehicleRentalToken");
        [owner, buyer] = await ethers.getSigners();
        token = await VehicleRentalToken.deploy(INITIAL_SUPPLY);
        await token.deployed();

        // Transfer tokens to the ICO contract
        VehicleRentalICO = await ethers.getContractFactory("VehicleRentalICO");
        ico = await VehicleRentalICO.deploy(token.address);
        await ico.deployed();

        await token.transfer(ico.address, INITIAL_SUPPLY);
    });

    it("should allow users to purchase tokens", async function () {
        const purchaseAmount = 10;
        const totalEther = TOKEN_PRICE.mul(purchaseAmount);

        await expect(
            ico.connect(buyer).buyTokens(purchaseAmount, { value: totalEther })
        )
            .to.emit(ico, "TokensPurchased")
            .withArgs(buyer.address, purchaseAmount);

        const buyerBalance = await token.balanceOf(buyer.address);
        expect(buyerBalance).to.equal(purchaseAmount);

        const totalTokensSold = await ico.getTotalTokensSold();
        expect(totalTokensSold).to.equal(purchaseAmount);
    });

    it("should revert if incorrect Ether amount is sent", async function () {
        const purchaseAmount = 10;
        const incorrectEther = TOKEN_PRICE.mul(purchaseAmount).sub(ethers.utils.parseEther("1"));

        await expect(
            ico.connect(buyer).buyTokens(purchaseAmount, { value: incorrectEther })
        ).to.be.revertedWithCustomError(ico, "InvalidPurchaseAmount");
    });

    it("should revert if not enough tokens are available", async function () {
        const purchaseAmount = INITIAL_SUPPLY + 1;
        const totalEther = TOKEN_PRICE.mul(purchaseAmount);

        await expect(
            ico.connect(buyer).buyTokens(purchaseAmount, { value: totalEther })
        ).to.be.revertedWithCustomError(ico, "InsufficientTokens");
    });

    it("should allow owner to end the ICO and transfer remaining tokens", async function () {
        const remainingTokens = await token.balanceOf(ico.address);

        await expect(ico.endICO())
            .to.emit(ico, "ICOEnded")
            .withArgs(owner.address, 0);

        const ownerBalance = await token.balanceOf(owner.address);
        expect(ownerBalance).to.equal(remainingTokens);
    });

    it("should allow owner to withdraw funds", async function () {
        const purchaseAmount = 10;
        const totalEther = TOKEN_PRICE.mul(purchaseAmount);

        await ico.connect(buyer).buyTokens(purchaseAmount, { value: totalEther });

        const contractBalanceBefore = await ethers.provider.getBalance(ico.address);
        expect(contractBalanceBefore).to.equal(totalEther);

        const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);

        const tx = await ico.withdrawFunds();
        const receipt = await tx.wait();

        const gasUsed = receipt.gasUsed.mul(tx.gasPrice);
        const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);

        expect(ownerBalanceAfter).to.equal(ownerBalanceBefore.add(totalEther).sub(gasUsed));

        const contractBalanceAfter = await ethers.provider.getBalance(ico.address);
        expect(contractBalanceAfter).to.equal(0);
    });

    it("should return buyer balances correctly", async function () {
        const purchaseAmount = 10;
        const totalEther = TOKEN_PRICE.mul(purchaseAmount);

        await ico.connect(buyer).buyTokens(purchaseAmount, { value: totalEther });

        const buyerBalance = await ico.getBuyerBalance(buyer.address);
        expect(buyerBalance).to.equal(purchaseAmount);
    });
});
