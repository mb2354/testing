// Import Hardhat test environment
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("VehicleRentalToken Contract", function () {
    let VehicleRentalToken, token;
    let admin, minter, user;

    beforeEach(async function () {
        // Deploy the VehicleRentalToken contract
        VehicleRentalToken = await ethers.getContractFactory("VehicleRentalToken");
        [admin, minter, user] = await ethers.getSigners();
        token = await VehicleRentalToken.deploy(admin.address);
        await token.deployed();
    });

    it("should assign the initial supply to the admin", async function () {
        const adminBalance = await token.balanceOf(admin.address);
        const totalSupply = await token.totalSupply();
        expect(adminBalance).to.equal(totalSupply);
    });

    it("should allow admin to mint new tokens", async function () {
        const mintAmount = ethers.utils.parseEther("100");

        await token.connect(admin).mint(user.address, mintAmount);

        const userBalance = await token.balanceOf(user.address);
        expect(userBalance).to.equal(mintAmount);

        const totalSupply = await token.totalSupply();
        expect(totalSupply).to.equal(ethers.utils.parseEther("1000000").add(mintAmount));
    });

    it("should emit TokensMinted event when tokens are minted", async function () {
        const mintAmount = ethers.utils.parseEther("100");

        await expect(token.connect(admin).mint(user.address, mintAmount))
            .to.emit(token, "TokensMinted")
            .withArgs(user.address, mintAmount);
    });

    it("should revert minting if caller is not a minter", async function () {
        const mintAmount = ethers.utils.parseEther("100");

        await expect(
            token.connect(user).mint(user.address, mintAmount)
        ).to.be.revertedWithCustomError(token, "InsufficientPermissions");
    });

    it("should allow users to burn their own tokens", async function () {
        const burnAmount = ethers.utils.parseEther("50");
        await token.connect(admin).transfer(user.address, burnAmount);

        await token.connect(user).burn(burnAmount);

        const userBalance = await token.balanceOf(user.address);
        expect(userBalance).to.equal(0);

        const totalSupply = await token.totalSupply();
        expect(totalSupply).to.equal(ethers.utils.parseEther("1000000").sub(burnAmount));
    });

    it("should emit TokensBurned event when tokens are burned", async function () {
        const burnAmount = ethers.utils.parseEther("50");
        await token.connect(admin).transfer(user.address, burnAmount);

        await expect(token.connect(user).burn(burnAmount))
            .to.emit(token, "TokensBurned")
            .withArgs(user.address, burnAmount);
    });
});
