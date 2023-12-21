// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

struct Tweet {
    string text;
    bool isDeleted;
    uint256 editedAt;
}

contract TwitterMessages {
    mapping(address => Tweet[]) internal tweets;

    function createTweet(string memory _message) public {
        tweets[msg.sender].push(
            Tweet({text: _message, isDeleted: false, editedAt: block.timestamp})
        );
    }

    function getOneTweet(address _owner, uint8 _i)
        public
        view
        returns (Tweet memory)
    {
        return tweets[_owner][_i];
    }

    function getAllTweets(address _owner) public view returns (Tweet[] memory) {
        return tweets[_owner];
    }

    function deleteTweet(address _owner, uint8 _i) public {
        tweets[_owner][_i].isDeleted = true;
    }
}
