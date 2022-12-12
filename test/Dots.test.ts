import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Contract, ContractFactory } from 'ethers';
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
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    const price = BASE_PRICE.add(EPSILON);
    await contract.connect(addresses[0]).claimLocation(0, 0, 0, 1, {
      value: String(BASE_PRICE),
    });
    await expect(
      contract.connect(owner).claimLocation(0, 0, 0, 2, {
        value: String(price),
      })
    )
      .to.emit(contract, 'Transfer')
      .withArgs(0, 0, 0, price, BASE_PRICE, 2, 1);
  });

  it('should RE-claim successfully', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    const price = BASE_PRICE.add(EPSILON);
    await contract.connect(addresses[0]).claimLocation(0, 0, 0, 1, {
      value: String(BASE_PRICE),
    });
    await expect(
      contract.claimLocation(0, 0, 0, 2, {
        value: String(price),
      })
    )
      .to.emit(contract, 'Transfer')
      .withArgs(0, 0, 0, price, BASE_PRICE, 2, 1);
  });

  it('should revert with InsufficientBasePrice', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    await expect(
      contract.claimLocation(0, 0, 0, 1)
    ).to.be.revertedWithCustomError(contract, 'InsufficientBasePrice');
  });

  // it('should RE-claim successfully', async () => {
  //   await contract.connect(addresses[0]).claimLocation(0, 0, 1, {
  //     value: String(BASE_PRICE),
  //   });
  //   await expect(contract.claimLocation(0, 0, 1)).to.be.revertedWithCustomError(
  //     contract,
  //     'InsufficientPrice'
  //   );
  // });

  it('should UndefinedCoordinates', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );

    await expect(
      contract.claimLocation(0, 0, 51, 1, {
        value: String(BASE_PRICE),
      })
    ).to.be.revertedWithCustomError(contract, 'UndefinedCoordinates');
  });
  it('should UndefinedCountry', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );

    await expect(
      contract.claimLocation(0, 0, 0, 0, {
        value: String(BASE_PRICE),
      })
    ).to.be.revertedWithCustomError(contract, 'UndefinedCountry');
  });
  it('should not vest while game is continuing', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    await contract.claimLocation(0, 0, 0, 1, { value: String(BASE_PRICE) });
    await contract.claimLocation(0, 0, 1, 1, { value: String(BASE_PRICE) });
    await expect(contract.withdrawVesting(0)).to.be.revertedWithCustomError(
      contract,
      'GameIsActive'
    );
  });
  it('Should vest correctly', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    let overallGasPrice = BigNumber.from('0');
    const initialBalanceOfOwner = await ethers.provider.getBalance(
      owner.address
    );

    // Transaction 1
    const tx1 = await contract.claimLocation(0, 0, 0, 1, {
      value: String(BASE_PRICE),
    });
    const tc1 = await tx1.wait(1);
    overallGasPrice = overallGasPrice.add(
      tc1.gasUsed.mul(tc1.effectiveGasPrice)
    );

    // Transaction 2
    const tx2 = await contract.claimLocation(0, 0, 1, 1, {
      value: String(BASE_PRICE),
    });
    const tc2 = await tx2.wait(1);
    overallGasPrice = overallGasPrice.add(
      tc2.gasUsed.mul(tc2.effectiveGasPrice)
    );
    // Transaction 3
    const tx3 = await contract.finishGame();
    const tc3 = await tx3.wait(1);
    overallGasPrice = overallGasPrice.add(
      tc3.gasUsed.mul(tc3.effectiveGasPrice)
    );
    const stake = await contract.vestingStakes(0, owner.address);

    // Transaction 4
    const tx4 = await contract.withdrawVesting(0);
    const tc4 = await tx4.wait(1);
    overallGasPrice = overallGasPrice.add(
      tc4.gasUsed.mul(tc4.effectiveGasPrice)
    );
    const FinalBalanceOfOwner = await ethers.provider.getBalance(owner.address);
    const a = await contract.getGame(0);

    const vestAmount = a['treasury'].mul(stake).div(BigNumber.from('2500'));
    const expectedBalance = initialBalanceOfOwner
      .sub(overallGasPrice)
      .add(vestAmount)
      .sub(BASE_PRICE.mul(BigNumber.from('2')));
    expect(FinalBalanceOfOwner).to.be.equal(expectedBalance);
  });

  it('should track vest stakes properly', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    let contractAsSigner0 = contract.connect(addresses[0]);
    await contract.claimLocation(0, 0, 0, 1, { value: String(BASE_PRICE) });
    await contract.claimLocation(0, 0, 1, 1, { value: String(BASE_PRICE) });
    await contractAsSigner0.claimLocation(0, 0, 1, 5, {
      value: String(BASE_PRICE.add(ethers.utils.parseEther('1'))),
    });
    const ownerStake = await contract.vestingStakes(0, owner.address);
    const signer0Stake = await contract.vestingStakes(0, addresses[0].address);
    expect(ownerStake).to.be.equal(BigNumber.from('1'));
    expect(signer0Stake).to.be.equal(BigNumber.from('1'));
  });
  it('should revert if there is no stake', async () => {
    await contract.startGame(
      50,
      50,
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('0.01')
    );
    await contract.finishGame();
    await expect(contract.withdrawVesting(0)).to.be.revertedWithCustomError(
      contract,
      'NoVesting'
    );
  });
});
