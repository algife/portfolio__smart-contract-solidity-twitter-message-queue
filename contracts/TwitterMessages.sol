// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

struct Tweet {
    string text;
    address author;
    address[] likes; // keeps track of who liked it to be able to unlike it.
    bool isDeleted;
    uint256 editedAt;
    uint256 createdAt;
}

uint16 constant TEXT_MAX_LENGTH = 280;

contract TwitterMessages {
    mapping(address => Tweet[]) internal tweets;

    // GETTERS

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

    function getTweetLikes(address _owner, uint8 _i)
        public
        view
        returns (address[] memory)
    {
        return tweets[_owner][_i].likes;
    }

    // OPERATIONAL FUNCTIONS
    function createTweet(string memory _message) public {
        address[] memory noonelikedyet; // Initialize likes with an empty array

        // Limit the tweet length:
        require(
            bytes(_message).length <= TEXT_MAX_LENGTH,
            "Your tweet is too long!"
        );

        tweets[msg.sender].push(
            Tweet({
                author: msg.sender,
                text: _message,
                isDeleted: false,
                createdAt: block.timestamp,
                editedAt: block.timestamp,
                likes: noonelikedyet
            })
        );
    }

    function deleteTweet(address _owner, uint8 _i) public {
        tweets[_owner][_i].isDeleted = true;
    }

    function updateTweet(
        address _owner,
        uint8 _i,
        string memory _message
    ) public {
        require(
            !tweets[_owner][_i].isDeleted,
            "Deleted tweets cannot be edited."
        );

        tweets[_owner][_i].text = _message;
        tweets[_owner][_i].editedAt = block.timestamp;
    }

    function likeTweet(address _owner, uint8 _ti) public {
        require(
            !tweets[_owner][_ti].isDeleted,
            "Deleted tweets cannot be liked."
        );

        // Check if the sender has already liked the tweet and toggle its like/Unlike status
        if (tweets[_owner][_ti].likes.length == 0)
            tweets[_owner][_ti].likes.push(msg.sender);
        else {
            /* ⚠️ A mapping would be ideal but nested mappings are not allowed so I had to use
             a for loop rather than creating a completely isolated struct */
            for (uint8 _li = 0; _li < tweets[_owner][_ti].likes.length; _li++) {
                _changeLikedAddressIfProceeds(_owner, _ti, _li);
            }
        }
    }

    function _changeLikedAddressIfProceeds(
        address _owner,
        uint8 _ti,
        uint8 _li
    ) internal {
        // Only the sender is allowed to change its status
        if (tweets[_owner][_ti].likes[_li] == msg.sender) {
            // Unlike it.
            delete tweets[_owner][_ti].likes[_li];
        }
        // Otherwise, If we're at the end and sender has not
        // been found, then like it.
        else if (_li == tweets[_owner][_ti].likes.length - 1) {
            // If is address(0), switch it for its address, otherwise
            // push the new liked address to the array
            if (tweets[_owner][_ti].likes[_li] == address(0)) {
                tweets[_owner][_ti].likes[_li] = msg.sender;
            } else {
                tweets[_owner][_ti].likes.push(msg.sender);
            }
        }
    }
}
