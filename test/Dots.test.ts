import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract, ContractFactory } from 'ethers';
import { ethers } from 'hardhat';

const name: string = 'Dots';

describe(name, () => {
  let contract: Contract;
  let factory: ContractFactory;
  let owner: SignerWithAddress;
  let addresses: SignerWithAddress[];
  const BASE_PRICE = ethers.utils.parseEther('0.1');
  const EPSILON = ethers.utils.parseEther('0.01');

  // hooks
  before(async () => {
    [owner, ...addresses] = await ethers.getSigners();
    factory = await ethers.getContractFactory(name);
  });

  beforeEach(async () => {
    contract = await factory.deploy();
  });

  // claim tests
  it('should claim successfully', async () => {
    const price = BASE_PRICE.add(EPSILON);
    await contract.connect(addresses[0]).claimLocation(0, 0, 1, {
      value: String(BASE_PRICE),
    });
    await expect(
      contract.connect(owner).claimLocation(0, 0, 2, {
        value: String(price),
      })
    )
      .to.emit(contract, 'Transfer')
      .withArgs(0, 0, price, 2);
  });

  it('should RE-claim successfully', async () => {
    const price = BASE_PRICE.add(EPSILON);
    await contract.connect(addresses[0]).claimLocation(0, 0, 1, {
      value: String(BASE_PRICE),
    });
    await expect(
      contract.claimLocation(0, 0, 2, {
        value: String(price),
      })
    )
      .to.emit(contract, 'Transfer')
      .withArgs(0, 0, price, 2);
  });

  it('should revert with InsufficientBasePrice', async () => {
    await expect(contract.claimLocation(0, 0, 1)).to.be.revertedWithCustomError(
      contract,
      'InsufficientBasePrice'
    );
  });

  it('should RE-claim successfully', async () => {
    await contract.connect(addresses[0]).claimLocation(0, 0, 1, {
      value: String(BASE_PRICE),
    });
    await expect(contract.claimLocation(0, 0, 1)).to.be.revertedWithCustomError(
      contract,
      'InsufficientPrice'
    );
  });

  it('should UndefinedCoordinates', async () => {
    await expect(
      contract.claimLocation(0, 51, 1, {
        value: String(BASE_PRICE),
      })
    ).to.be.revertedWithCustomError(contract, 'UndefinedCoordinates');
  });
  it('should UndefinedCountry', async () => {
    await expect(
      contract.claimLocation(0, 0, 0, {
        value: String(BASE_PRICE),
      })
    ).to.be.revertedWithCustomError(contract, 'UndefinedCountry');
  });
});
