// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

struct Tweet {
    uint32 id;
    string text;
    address author;
    bool isDeleted;
    address[] likedBy; // keeps track of who liked what tweet
    uint32 likeCount;
    uint256 createdAt;
    uint256 editedAt;
}

struct User {
    uint32 id;
    string username;
    uint8 roleLevel;
    bool isDeleted;
    uint256 createdAt;
    uint256 editedAt;
}

contract TwitterMessages {
    uint16 MAX_TWEET_LENGTH = 280;
    address internal owner;
    string internal publicName;
    bool private paused;
    mapping(address => User) public users;
    mapping(address => Tweet[]) internal tweets;
    mapping(address => uint32) internal creditBalances;

    // Blockchain Events
    event NewUserRegisteredEvent(address indexed userAddress, string userName);
    event PausedStatusChangeEvent(bool newStatus, uint256 timestamp);
    event TweetCreatedEvent(
        uint32 indexed id,
        address author,
        string text,
        uint256 timestamp
    );
    event TweetEditedEvent(
        uint32 indexed id,
        address author,
        string newText,
        uint256 timestamp
    );
    event TweetLikedEvent(
        uint32 indexed id,
        address liker,
        bool newLikeStatus,
        uint32 likeCount,
        uint256 timestamp
    );
    event TweetDeletedEvent(
        uint32 indexed id,
        address author,
        uint256 timestamp
    );

    constructor() {
        owner = msg.sender;
        publicName = "fake name";
        creditBalances[owner] = 1000;
        paused = false;
    }

    function getOneTweet(address author, uint32 id)
        public
        view
        returns (Tweet memory)
    {
        return tweets[author][id];
    }

    function getAllTweets(address author) public view returns (Tweet[] memory) {
        return tweets[author];
    }

    function getTweetLikes(address author, uint32 id)
        public
        view
        returns (address[] memory)
    {
        return tweets[author][id].likedBy;
    }

    function changeTweetLength(uint16 newTweetLength) public {
        MAX_TWEET_LENGTH = newTweetLength;
    }

    // OPERATIONS
    function createTweet(string memory tweetText) public {
        address author = msg.sender;

        // Limit the tweet length
        require(
            bytes(tweetText).length <= MAX_TWEET_LENGTH,
            "Your tweet is too long!"
        );

        uint32 id = uint32(tweets[author].length);
        uint256 timestamp = block.timestamp;

        address[] memory noLikes; // Initialize as empty tuple
        Tweet memory newTweet = Tweet({
            id: id,
            text: tweetText,
            author: author,
            isDeleted: false,
            createdAt: timestamp,
            editedAt: timestamp,
            likeCount: 0,
            likedBy: noLikes
        });
        tweets[author].push(newTweet);
        emit TweetCreatedEvent(
            newTweet.id,
            author,
            newTweet.text,
            newTweet.createdAt
        );
    }

    function deleteTweet(uint32 id) public {
        address author = msg.sender;
        require(tweets[author][id].id == id, "The Tweet does not exists");
        require(!tweets[author][id].isDeleted, "The Tweet was already deleted");
        tweets[author][id].isDeleted = true;
        uint256 timestamp = block.timestamp;
        emit TweetDeletedEvent(id, author, timestamp);
    }

    function updateTweet(uint32 id, string memory _message) public {
        address author = msg.sender;
        require(
            !tweets[author][id].isDeleted,
            "Deleted tweets cannot be edited."
        );
        uint256 timestamp = block.timestamp;
        //         tweets[author][id].editedAt = timestamp;
        tweets[author][id].text = _message;
        emit TweetEditedEvent(id, author, _message, timestamp);
    }

    function likeTweet(address author, uint32 id) external {
        address sender = msg.sender;
        require(sender != author, "You cannot like your own tweet!");
        require(tweets[author][id].id == id, "The tweet does not exists");
        require(
            !tweets[author][id].isDeleted,
            "Deleted tweets cannot be liked."
        );
        uint256 timestamp = block.timestamp;

        // Check if the sender has already liked the tweet and toggle its like/unlike status
        if (tweets[author][id].likedBy.length == 0) {
            tweets[author][id].likedBy.push(sender);
            tweets[author][id].likeCount = 1; // Update Like count accordingly.
            emit TweetLikedEvent(
                id,
                author,
                true,
                tweets[author][id].likeCount,
                timestamp
            );
        } else {
            /* ⚠️ A mapping would be ideal but nested mappings are not allowed so I had to use
                    a for loop rather than creating a completely isolated struct */
            for (
                uint8 _li = 0;
                _li < tweets[author][id].likedBy.length;
                _li++
            ) {
                _changeLikedAddressIfProceeds(author, id, _li, timestamp);
            }
        }
    }

    function _changeLikedAddressIfProceeds(
        address author,
        uint32 id,
        uint8 _li,
        uint256 timestamp
    ) internal {
        // Only the sender is allowed to change its status
        if (tweets[author][id].likedBy[_li] == msg.sender) {
            // Unlike it.
            delete tweets[author][id].likedBy[_li];
            tweets[author][id].likeCount--; // Update Like count accordingly.
            emit TweetLikedEvent(
                id,
                author,
                false,
                tweets[author][id].likeCount,
                timestamp
            );
        }
        // Otherwise, If we're at the end and sender has not
        // been found, then like it.
        else if (_li == tweets[author][id].likedBy.length - 1) {
            // If is address(0) --default value--, switch it for its
            // address, otherwise push the new liked address to the array
            // if (tweets[author][id].likedBy[_li] == address(0)) {
            // tweets[author][id].likedBy[_li] = msg.sender;
            // } else {
            tweets[author][id].likedBy.push(msg.sender);
            // }
            // finnally:
            tweets[author][id].likeCount++; // Update Like count accordingly.
            emit TweetLikedEvent(
                id,
                author,
                true,
                tweets[author][id].likeCount,
                timestamp
            );
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

    function transfer(address to, uint32 amount) public notPaused {
        address sender = msg.sender;
        require(to != sender, "Please, introduce different accounts.");
        require(
            creditBalances[sender] > amount,
            "You've insufficient credit balance to being able to transfer that amount."
        );
        creditBalances[sender] -= amount;
        creditBalances[to] += amount;
    }

    // ONLY-OWNER ACTIONS
    function isPaused() public view onlyOwner returns (bool) {
        return paused;
    }

    function updateName(string memory newData) public onlyOwner notPaused {
        publicName = newData;
    }

    function setPauseStatus(bool newStatus) public onlyOwner {
        paused = newStatus;
        uint256 timestamp = block.timestamp;
        emit PausedStatusChangeEvent(newStatus, timestamp);
    }

    function addUser(string memory _username, uint8 _roleLvl) public notPaused {
        uint256 timestamp = block.timestamp;
        User storage newUser = users[msg.sender];

        newUser.username = _username;
        newUser.roleLevel = _roleLvl;
        newUser.isDeleted = false;
        newUser.createdAt = timestamp;
        newUser.editedAt = timestamp;

        // EMIT EVENT
        emit NewUserRegisteredEvent(msg.sender, _username);
    }
}
