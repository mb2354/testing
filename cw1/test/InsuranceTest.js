// Import Hardhat test environment
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Insurance Contract", function () {
    let Insurance, insurance;
    let owner, addr1;

    beforeEach(async function () {
        // Deploy the contract
        Insurance = await ethers.getContractFactory("Insurance");
        [owner, addr1] = await ethers.getSigners();
        insurance = await Insurance.deploy();
        await insurance.deployed();
    });

    it("should purchase an insurance policy", async function () {
        const premium = ethers.utils.parseEther("1");
        const coverage = ethers.utils.parseEther("10");
        const duration = 3600; // 1 hour

        await expect(
            insurance.purchasePolicy(1, 1, 10, duration, { value: premium })
        )
            .to.emit(insurance, "PolicyPurchased")
            .withArgs(1, owner.address, 1, premium, coverage, await ethers.provider.getBlock("latest").then(b => b.timestamp + duration));

        const policy = await insurance.getPolicy(1);
        expect(policy.vehicleOwner).to.equal(owner.address);
        expect(policy.premium).to.equal(premium);
        expect(policy.coverageAmount).to.equal(coverage);
        expect(policy.isActive).to.be.true;
    });

    it("should allow policy owner to claim coverage", async function () {
        const premium = ethers.utils.parseEther("1");
        const coverage = ethers.utils.parseEther("10");
        const claimAmount = ethers.utils.parseEther("5");

        await insurance.purchasePolicy(1, 1, 10, 3600, { value: premium });

        await expect(insurance.claimPolicy(1, 5))
            .to.emit(insurance, "PolicyClaimed")
            .withArgs(1, claimAmount);

        const policy = await insurance.getPolicy(1);
        expect(policy.coverageAmount).to.equal(coverage.sub(claimAmount));
    });

    it("should revert if non-policy owner attempts to claim", async function () {
        const premium = ethers.utils.parseEther("1");
        await insurance.purchasePolicy(1, 1, 10, 3600, { value: premium });

        await expect(
            insurance.connect(addr1).claimPolicy(1, 5)
        ).to.be.revertedWithCustomError(insurance, "NotPolicyOwner");
    });

    it("should cancel a policy", async function () {
        const premium = ethers.utils.parseEther("1");
        await insurance.purchasePolicy(1, 1, 10, 3600, { value: premium });

        await expect(insurance.cancelPolicy(1))
            .to.emit(insurance, "PolicyCancelled")
            .withArgs(1);

        const policy = await insurance.getPolicy(1);
        expect(policy.isActive).to.be.false;
    });

    it("should check if a vehicle has an active policy", async function () {
        const premium = ethers.utils.parseEther("1");
        await insurance.purchasePolicy(1, 1, 10, 3600, { value: premium });

        const hasPolicy = await insurance.hasActivePolicy(1);
        expect(hasPolicy).to.be.true;

        await insurance.cancelPolicy(1);

        const hasPolicyAfterCancel = await insurance.hasActivePolicy(1);
        expect(hasPolicyAfterCancel).to.be.false;
    });

    it("should revert if claim exceeds coverage", async function () {
        const premium = ethers.utils.parseEther("1");
        const coverage = ethers.utils.parseEther("10");
        await insurance.purchasePolicy(1, 1, 10, 3600, { value: premium });

        await expect(
            insurance.claimPolicy(1, 20) // Claim exceeds coverage
        ).to.be.revertedWithCustomError(insurance, "ClaimExceedsCoverage");
    });

    it("should revert if policy is expired", async function () {
        const premium = ethers.utils.parseEther("1");
        const duration = 1; // 1 second

        await insurance.purchasePolicy(1, 1, 10, duration, { value: premium });
        await new Promise((resolve) => setTimeout(resolve, 2000)); // Wait for expiration

        await expect(
            insurance.claimPolicy(1, 1)
        ).to.be.revertedWithCustomError(insurance, "PolicyExpired");
    });
});
