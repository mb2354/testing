// Import Hardhat test environment
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Asset Contract", function () {
    let Asset, asset;
    let owner, addr1, addr2;

    beforeEach(async function () {
        // Deploy the contract
        Asset = await ethers.getContractFactory("Asset");
        [owner, addr1, addr2] = await ethers.getSigners();
        asset = await Asset.deploy();
        await asset.deployed();
    });

    it("should register a vehicle", async function () {
        await expect(
            asset.registerVehicle(0, ethers.utils.parseEther("1"), 1672531199) // Car category, 1 ETH/day, mock maintenance date
        )
            .to.emit(asset, "VehicleRegistered")
            .withArgs(1, owner.address, 0);

        const vehicle = await asset.getVehicle(1);
        expect(vehicle.owner).to.equal(owner.address);
        expect(vehicle.category).to.equal(0);
        expect(vehicle.rentalPrice).to.equal(ethers.utils.parseEther("1"));
        expect(vehicle.isAvailable).to.be.true;
    });

    it("should update a vehicle's details", async function () {
        await asset.registerVehicle(0, ethers.utils.parseEther("1"), 1672531199);

        await expect(
            asset.updateVehicle(1, ethers.utils.parseEther("2"), false, true)
        )
            .to.emit(asset, "VehicleUpdated")
            .withArgs(1, ethers.utils.parseEther("2"), false, true);

        const vehicle = await asset.getVehicle(1);
        expect(vehicle.rentalPrice).to.equal(ethers.utils.parseEther("2"));
        expect(vehicle.isAvailable).to.be.false;
        expect(vehicle.hasInsurance).to.be.true;
    });

    it("should revert update if not the owner", async function () {
        await asset.registerVehicle(0, ethers.utils.parseEther("1"), 1672531199);

        await expect(
            asset.connect(addr1).updateVehicle(1, ethers.utils.parseEther("2"), false, true)
        ).to.be.revertedWithCustomError(asset, "NotOwner");
    });

    it("should transfer ownership", async function () {
        await asset.registerVehicle(0, ethers.utils.parseEther("1"), 1672531199);

        await expect(asset.transferOwnership(1, addr1.address))
            .to.emit(asset, "OwnershipTransferred")
            .withArgs(1, addr1.address);

        const vehicle = await asset.getVehicle(1);
        expect(vehicle.owner).to.equal(addr1.address);
    });

    it("should revert transfer if not the owner", async function () {
        await asset.registerVehicle(0, ethers.utils.parseEther("1"), 1672531199);

        await expect(
            asset.connect(addr1).transferOwnership(1, addr2.address)
        ).to.be.revertedWithCustomError(asset, "NotOwner");
    });

    it("should check vehicle availability", async function () {
        await asset.registerVehicle(0, ethers.utils.parseEther("1"), 1672531199);

        let isAvailable = await asset.isAvailable(1);
        expect(isAvailable).to.be.true;

        await asset.updateVehicle(1, ethers.utils.parseEther("1"), false, false);

        isAvailable = await asset.isAvailable(1);
        expect(isAvailable).to.be.false;
    });
});
