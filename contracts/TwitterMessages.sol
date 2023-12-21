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
    mapping(address => uint256) internal creditBalances;
    bool private paused;

    constructor() {
        owner = msg.sender;
        contactEmail = "fake@email.com";
        creditBalances[owner] = 1000;
        paused = false;
    }

    function getOneTweet(address author, uint256 id) public view returns (Tweet memory) {
        return tweets[author][id];
    }

    function getAllTweets(address author) public view returns (Tweet[] memory) {
        return tweets[author];
    }

    function getTweetLikes(address author, uint256 id) public view returns (address[] memory) {
        return tweets[author][id].likes;
    }

    // OPERATIONAL FUNCTIONS
    function createTweet(string memory _message) public {
        address author = msg.sender;
        address[] memory noonelikedyet; // Initialize likes with an empty array

        // Limit the tweet length:
        require(
            bytes(_message).length <= TEXT_MAX_LENGTH,
            "Your tweet is too long!"
        );

        tweets[author].push(
            Tweet({
                author: author,
                id: tweets[author].length,
                text: _message,
                isDeleted: false,
                createdAt: block.timestamp,
                editedAt: block.timestamp,
                likes: noonelikedyet
            })
        );
    }

    function deleteTweet(uint256 id) public {
        address author = msg.sender;
        require(tweets[author][id].id == id, "The Tweet does not exists");
        require(!tweets[author][id].isDeleted, "The Tweet was already deleted");
        tweets[author][id].isDeleted = true;
    }

    function updateTweet(uint256 id, string memory _message) public {
        address author = msg.sender;

        require(
            !tweets[author][id].isDeleted,
            "Deleted tweets cannot be edited."
        );

        tweets[author][id].text = _message;
        tweets[author][id].editedAt = block.timestamp;
    }

    function likeTweet(address author, uint256 id) external {
        address sender = msg.sender;

        require(tweets[author][id].id == id, "The tweet does not exists");
        require(
            !tweets[author][id].isDeleted,
            "Deleted tweets cannot be liked."
        );

        // Check if the sender has already liked the tweet and toggle its like/unlike status
        if (tweets[author][id].likes.length == 0)
            tweets[author][id].likes.push(sender);
        else {
            /* ⚠️ A mapping would be ideal but nested mappings are not allowed so I had to use
             a for loop rather than creating a completely isolated struct */
            for (uint8 _li = 0; _li < tweets[author][id].likes.length; _li++) {
                _changeLikedAddressIfProceeds(author, id, _li);
            }
        }
    }

    function _changeLikedAddressIfProceeds(
        address author,
        uint256 id,
        uint8 _li
    ) internal {
        // Only the sender is allowed to change its status
        if (tweets[author][id].likes[_li] == msg.sender) {
            // Unlike it.
            delete tweets[author][id].likes[_li];
        }
        // Otherwise, If we're at the end and sender has not
        // been found, then like it.
        else if (_li == tweets[author][id].likes.length - 1) {
            // If is address(0) --default value--, switch it for its
            // address, otherwise push the new liked address to the array
            if (tweets[author][id].likes[_li] == address(0)) {
                tweets[author][id].likes[_li] = msg.sender;
            } else {
                tweets[author][id].likes.push(msg.sender);
            }
        }
    }

    // MODIFIERS
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "This action can only be done by the owner of the target account/address."
        );
        _; // Continue logic ...
    }

    modifier notPaused() {
        require(!paused, "The contract is paused.");
        _;
    }

    function transfer(address to, uint256 amount) public notPaused {
        address sender = msg.sender;

        require(
            creditBalances[sender] > amount,
            "You've insufficient credit balance to being able to transfer that amount."
        );

        creditBalances[sender] -= amount;
        creditBalances[to] += amount;
    }

    // ONLY-OWNER ACTIONS
    function checkIfPaused() public view onlyOwner returns (bool) {
        return paused;
    }

    function updateEmail(string memory newEmail) public onlyOwner {
        contactEmail = newEmail;
    }

    function setPauseStatus(bool newStatus) public onlyOwner {
        paused = newStatus;
    }
}
