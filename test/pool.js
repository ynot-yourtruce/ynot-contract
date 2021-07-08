const YNOTFactory = artifacts.require("YNOTFactory");
const Genesis = artifacts.require("Genesis");
const Router = artifacts.require("Router");

contract('YNOTFactory', (accounts) => {
  it('should deploy Genesis, Router and Factory', async () => {
    const FactoryInstance = await YNOTFactory.deployed();
    const GenesisInstance = await Genesis.deployed();
    const RouterInstance = await Router.deployed();

    console.log(FactoryInstance.address, GenesisInstance.address, RouterInstance.address);
    //     assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, 'Library function returned unexpected function, linkage may be broken');
  });

});
