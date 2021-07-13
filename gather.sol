// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libs/token/ERC20/IERC20.sol";

contract GatherTest {
    address private admin;

    constructor() {
        admin = msg.sender;
    }

    struct Contributor {
        bool claimed;
        uint256 contributed;
    }

    struct Gather {
        address creator;
        IERC20 input;
        IERC20 output;
        uint256 maxAllocation;
        uint256 maxPerContributor;
        uint256 minPerContributor;
        uint256 allocated;
        uint256 fee;
        uint256 status;
        mapping (address => Contributor) contributors;
    }

    Gather[] public gathers;

    event Contributed(address indexed user, uint256 indexed gatherId, uint256 amount);
    event Claimed(address indexed user, uint256 indexed gatherId, uint256 amount);

    function startAGather(uint256 _maxAllocation, uint256 _maxPerContributor, uint256 _minPerContributor, uint256 _fee) public {
        // gathers.push(Gather({
        //         maxAllocation: _maxAllocation,
        //         maxPerContributor: _maxPerContributor,
        //         minPerContributor: _minPerContributor,
        //         fee: _fee,
        //         status: 0,
        //         contributors: 
        //     }));
    }

    /**
     * @dev contribute an amount of tokens to gather pool by id
     * Emits a {Contributed} event.
     */
    function contribute(uint256 _gId, uint256 _amount) public {
        Gather storage gg = gathers[_gId];
        require(gg.contributors[msg.sender].contributed + _amount <= gg.maxPerContributor, "Contribute: Max Allocation");
        require(gg.allocated + _amount <= gg.maxAllocation, "Contribute: Max Contributed");
        require(_amount <= gg.minPerContributor, "Contribute: Below Minimum Contributed");

        gg.input.transferFrom(msg.sender, address(this), _amount);

        gg.contributors[msg.sender].contributed += _amount;
        gg.allocated += _amount;

        emit Contributed(msg.sender, _gId, _amount);
    }


    /**
     * @dev claim tokens after sale ends
     */
    function claimTokens(uint256 _gId) public {
        Gather storage gg = gathers[_gId];
        require(gg.contributors[msg.sender].contributed > 0, "Claim: Not participated");
        require(gg.contributors[msg.sender].claimed == false, "Claim: Already Claimed");
        require(gg.status == 0, "Claim: Sale not ended");

        uint256 claimable = gg.contributors[msg.sender].contributed / gg.allocated * gg.output.balanceOf(address(this));

        gg.contributors[msg.sender].claimed = true;
        gg.output.transfer(msg.sender, claimable);

        emit Claimed(msg.sender, _gId, claimable);
    }

    /**
     * @dev transfer funds, only creator
     */
    function transferFunds(uint256 _gId, address _target) public {
        Gather storage gg = gathers[_gId];
        require(msg.sender == gg.creator, "Transfer: Not creator");
        gg.input.transfer(_target, gg.allocated);
        // todo: transfer && check output tokens amount
    }

    /**
     * @dev transfer funds, only admin
     */
    function transferFundsAdmin(IERC20 _token, uint256 _amount, address _target) public {
        require(msg.sender == admin, "?");
        _token.transfer(_target, _amount);
    }

}