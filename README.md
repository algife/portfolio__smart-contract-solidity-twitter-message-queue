# Solidity Smart Contract: User Tweets/messages array basic CRUD functionality

This ethereum/solidity smart contract allows to make operations related with "tweets" (messages) from/to a user account (blockchain address).
Includes the basic functionality that uses a mapping between a user account (address) and its tweet list. New messages can be added to the array of tweets, edited and retrieved (readed) one by one on request or all-at-once. Messages can be flagged as edited or deleted one a one-per-one basis.

> It is a demo smart contract for the portfolio.

#### CRUD Operations allowed:

  - [x] Update
  - [x] Create (Add new messages to the array)
  - [x] Read (one or all messages)
  - [x] Delete (soft-delete: flag as deleted)

## Showcase

![Loading...](https://github.com/algife/portfolio__smart-contract-solidity-twitter-message-queue/blob/main/showcase.gif)

## Workspace

> Developed using REMIX IDE.

This workspace contains the following directories:

1. 'contracts': Holds three contracts with increasing levels of complexity.
2. 'scripts': Contains typescript files to deploy contracts using 'web3.js' and 'ethers.js' libraries..
