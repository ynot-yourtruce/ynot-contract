const Factory = artifacts.require("YNOTFactory");
const Router = artifacts.require("Router");
const Genesis = artifacts.require("Genesis");

module.exports = function(deployer) {
  deployer.deploy(Factory).then(function() {
    return deployer.deploy(Router, Factory.address);
  });

  deployer.deploy(Genesis);
};
