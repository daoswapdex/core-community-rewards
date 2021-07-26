const CommunityRewards = artifacts.require("CommunityRewards"); 

module.exports = function(deployer) {
    deployer.deploy(CommunityRewards,
        '0xc096332CAacF00319703558988aD03eC6586e704' // DAO代币地址
    );
};