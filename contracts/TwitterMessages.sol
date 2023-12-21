// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

struct Tweet {
    uint256 id;
    string text;
    address author;
    address[] likes; // keeps track of who liked it to be able to unlike it.
    bool isDeleted;
    uint256 editedAt;
    uint256 createdAt;
}

uint16 constant TEXT_MAX_LENGTH = 280;

contract TwitterMessages {
    string internal contactEmail;
    address internal owner;
    mapping(address => Tweet[]) internal tweets;

    constructor() {
        owner = msg.sender;
        contactEmail = "fake@email.com";
    }

    // GETTERS
    function getOneTweet(uint256 id) public view returns (Tweet memory) {
        return tweets[owner][id];
    }

    function getAllTweets() public view returns (Tweet[] memory) {
        return tweets[owner];
    }

    function getTweetLikes(uint256 id) public view returns (address[] memory) {
        return tweets[owner][id].likes;
    }

    // OPERATIONAL FUNCTIONS
    function createTweet(string memory _message) public {
        address[] memory noonelikedyet; // Initialize likes with an empty array

        // Limit the tweet length:
        require(
            bytes(_message).length <= TEXT_MAX_LENGTH,
            "Your tweet is too long!"
        );

        tweets[owner].push(
            Tweet({
                author: owner,
                id: tweets[owner].length,
                text: _message,
                isDeleted: false,
                createdAt: block.timestamp,
                editedAt: block.timestamp,
                likes: noonelikedyet
            })
        );
    }

    function deleteTweet(uint256 id) public {
        require(tweets[owner][id].id == id, "The Tweet does not exists");
        require(!tweets[owner][id].isDeleted, "The Tweet was already deleted");
        tweets[owner][id].isDeleted = true;
    }

    function updateTweet(uint256 id, string memory _message) public {
        require(
            !tweets[owner][id].isDeleted,
            "Deleted tweets cannot be edited."
        );

        tweets[owner][id].text = _message;
        tweets[owner][id].editedAt = block.timestamp;
    }

    function likeTweet(uint256 id) external {
        require(tweets[owner][id].id == id, "The tweet does not exists");
        require(
            !tweets[owner][id].isDeleted,
            "Deleted tweets cannot be liked."
        );

        // Check if the sender has already liked the tweet and toggle its like/unlike status
        if (tweets[owner][id].likes.length == 0)
            tweets[owner][id].likes.push(owner);
        else {
            /* ⚠️ A mapping would be ideal but nested mappings are not allowed so I had to use
             a for loop rather than creating a completely isolated struct */
            for (uint8 _li = 0; _li < tweets[owner][id].likes.length; _li++) {
                _changeLikedAddressIfProceeds(id, _li);
            }
        }
    }

    function _changeLikedAddressIfProceeds(uint256 id, uint8 _li) internal {
        // Only the sender is allowed to change its status
        if (tweets[owner][id].likes[_li] == owner) {
            // Unlike it.
            delete tweets[owner][id].likes[_li];
        }
        // Otherwise, If we're at the end and sender has not
        // been found, then like it.
        else if (_li == tweets[owner][id].likes.length - 1) {
            // If is address(0), switch it for its address, otherwise
            // push the new liked address to the array
            if (tweets[owner][id].likes[_li] == address(0)) {
                tweets[owner][id].likes[_li] = owner;
            } else {
                tweets[owner][id].likes.push(owner);
            }
        }
    }

}
