const Factory = artifacts.require("Factory");
const Router = artifacts.require("Router");

module.exports = function(deployer) {
  deployer.deploy(Factory);
  deployer.deploy(Router);
};
