# Solidity Smart Contract: User Tweets/messages array basic CRUD functionality

This smart contract, inspired by Twitter, enables users to manage messages associated with their Ethereum blockchain address. It leverages a mapping to connect user accounts with tweet lists, allowing for basic tweet-related operations.

Key Features:

- Tweet Mapping: Establishes a link between tweet arrays and user accounts.
- State Tracking: Monitors "deleted" and "edited" statuses.
- CRUD Operations: Enables users to Create, Read, Update, and Delete individual tweets.
- Like Functionality: Permits users to like tweets by updating the relevant property and unlike them If they change their minds.
- Timestamped Struct: Utilizes a custom struct with timestamps for enhanced functionality.

> It is a demo smart contract for the portfolio.

#### CRUD Operations allowed:

- [x] Update: Edit a Tweet, like an unlike a Tweet.
- [x] Create: Post a new Tweet.
- [x] Read: Get One or All Tweets from a user.
- [x] Delete: Soft-delete a Tweet (flagging is as deleted while keeping its record)

## Showcase

![Loading...](https://github.com/algife/portfolio__smart-contract-solidity-twitter-message-queue/blob/main/showcase.gif)

## Workspace

> Developed using REMIX IDE.

This workspace contains the following directories:

1. 'contracts': Holds three contracts with increasing levels of complexity.
2. 'scripts': Contains typescript files to deploy contracts using 'web3.js' and 'ethers.js' libraries..
