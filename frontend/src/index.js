import dotenv from "dotenv";
import contractABI from "./abi.json";

dotenv.config(); // Load env vars

// Smart contract address 👇
const contractAddress = process.env.CONTRACT_ADDRESS;
// const SUGGESTED_GAS_LIMIT = "5000000000000000"; // default gas price in wei, 20 gwei in this case
let connectedAccountAddress = "";

if (!contractAddress)
  throw new Error("Contract address not specified in the env vars.");

// Connect to the contract using web3:
// https://web3js.readthedocs.io/en/v1.2.11/web3-eth-contract.html#new-contract
let web3 = new Web3(window.ethereum);
let dAppContract = new web3.eth.Contract(contractABI, contractAddress);

function getHtmlElements() {
  return {
    userAddress: document.getElementById("userAddress"),
    connectMessage: document.getElementById("connectMessage"),
    connectWalletBtn: document.getElementById("connectWalletBtn"),
    tweetForm: document.getElementById("tweetForm"),
    tweetsContainer: document.getElementById("tweetsContainer"),
    connectWalletBtn: document.getElementById("connectWalletBtn"),
    tweetContent: document.getElementById("tweetContent"),
    tweetSubmitBtn: document.getElementById("tweetSubmitBtn"),
  };
}

async function isPaused() {
  const isPaused = await dAppContract.methods.isPaused().call({
    from: connectedAccountAddress,
  });

  if (isPaused) console.error("The contract is paused. Contact the owner.");

  return isPaused;
}

async function connectWallet() {
  // Request Wallet Connection from Metamask
  // https://docs.metamask.io/wallet/get-started/set-up-dev-environment/
  try {
    const { userAddress, connectMessage, tweetForm } = getHtmlElements();

    if (!window.ethereum || !web3.eth) {
      console.error("No web3 provider detected");
      connectMessage.innerText =
        "No web3 provider detected. Please install MetaMask.";
    } else {
      // const accounts  = await window.ethereum.request({
      //   method: "eth_requestAccounts",
      // });
      const accounts = await web3.eth.getAccounts();
      connectedAccountAddress = accounts[0];
      if (!connectedAccountAddress)
        throw new Error("Account address not set-up");

      connectWalletBtn.style.display = "none"; // hide the button
      connectMessage.style.display = "none"; // hide the message
      userAddress.innerText =
        "Account Connected: " + shortAddress(connectedAccountAddress);
      tweetForm.style.display = "block";

      if (connectedAccountAddress === process.env.OWNER_ADDRESS)
        await isPaused();

      // Call the JS function (not smart contract) displayTweets function with address as input
      // to display all tweets after connecting to metamask
      await displayTweets();
    }
  } catch (err) {
    if (err.code === 4001) {
      console.log("Please connect to MetaMask.");
    } else {
      console.error(err);
    }
  }
}

async function createTweet(tweetText) {
  try {
    // Call the contract createTweet method in order to create the actual TWEET
    // https://web3js.readthedocs.io/en/v1.2.11/web3-eth-contract.html#methods-mymethod-send
    await dAppContract.methods.createTweet(tweetText).send({
      from: connectedAccountAddress,
    });
    // Await for its execution and then reload tweets after creating a new tweet
    await displayTweets();
  } catch (error) {
    console.error("[createTweet] User rejected request:", error);
  }
}

async function fetchTweets() {
  try {
    // Fetch tweets
    let tweets = [];
    const userTweets = await dAppContract.methods
      .getAllTweets(connectedAccountAddress) // from a user account
      .call({
        from: connectedAccountAddress,
      });

    // Spread and Sort them
    tweets = [...userTweets];

    tweets.sort((a, b) => Number(b.createdAt) - Number(a.createdAt));
    return tweets;
  } catch (err) {
    console.error("Error fetching all tweets:", err);
    return [];
  }
}

async function displayTweets() {
  const { tweetsContainer } = getHtmlElements();
  tweetsContainer.innerHTML = "";
  // Call the function getAllTweets from smart contract to fetch all the tweets
  // https://web3js.readthedocs.io/en/v1.2.11/web3-eth-contract.html#methods-mymethod-call
  const tweets = await fetchTweets();

  // Build the html blocks for displaying the tweets.
  tweets.forEach(buildTweetsHtmlBlocks);
}

function buildTweetsHtmlBlocks(tweetItem) {
  if (tweetItem.isDeleted) return; // Ignore this block if the tweet has been soft deleted.

  const tweetElem = document.createElement("div");
  tweetElem.className = "tweet";

  // ! User icon
  const userIcon = document.createElement("img");
  userIcon.className = "user-icon";
  userIcon.src = `https://api.dicebear.com/7.x/avataaars/svg?seed=${tweetItem.author}`;
  userIcon.alt = "User Icon";

  tweetElem.appendChild(userIcon);

  // ! Tweet content (author + text)
  const tweetInner = document.createElement("div");
  tweetInner.className = "tweet-inner";
  tweetInner.innerHTML += `
      <div class="author">${shortAddress(tweetItem.author)}</div>
      <div class="text">${tweetItem.text}</div>
  `;

  // ! Like button
  const likeButtonElem = document.createElement("button");
  likeButtonElem.className = "like-button";
  likeButtonElem.innerHTML = `
      <i class="far fa-heart"></i>
      <span class="likes-count">${tweetItem.likedBy.length}</span>
  `;
  likeButtonElem.setAttribute("data-id", tweetItem.id);
  likeButtonElem.setAttribute("data-author", tweetItem.author);

  // Append elements
  tweetInner.appendChild(likeButtonElem);
  tweetElem.appendChild(tweetInner);
  tweetsContainer.appendChild(tweetElem);

  // Start listeners
  addLikeButtonListener(likeButtonElem, tweetItem.author, tweetItem.id);
}

function addLikeButtonListener(likeButtonElem, author, id) {
  const onLikeBtnClicked = async (e) => {
    e.preventDefault();

    e.currentTarget.innerHTML = '<div class="spinner"></div>';
    e.currentTarget.disabled = true;
    try {
      await likeTweet(author, id);
      await displayTweets();
    } catch (error) {
      console.error("Error liking tweet:", error);
    }
  };
  likeButtonElem.addEventListener("click", onLikeBtnClicked);
}

function shortAddress(address, startLength = 6, endLength = 4) {
  return `${address.slice(0, startLength)}...${address.slice(-endLength)}`;
}

async function likeTweet(author, id) {
  try {
    // Call the likeTweet function from the smart contract to
    // save the like in the smart contract
    await dAppContract.methods.likeTweet(author, id).send({
      from: connectedAccountAddress,
      // gasPrice: SUGGESTED_GAS_LIMIT
    });
  } catch (error) {
    console.error("User rejected request:", error);
  }
}

async function submitTweetForm(e) {
  e.preventDefault();

  const { tweetContent, tweetSubmitBtn } = getHtmlElements();

  const tweetText = tweetContent.value;
  tweetSubmitBtn.innerHTML = '<div class="spinner"></div>';
  tweetSubmitBtn.disabled = true;

  try {
    await createTweet(tweetText);
  } catch (err) {
    console.error("Error sending tweet:", err);
  } finally {
    // Restore the original button text
    tweetSubmitBtn.innerHTML = "Tweet";
    tweetSubmitBtn.disabled = false;
  }
}

(function main() {
  const { connectWalletBtn, tweetForm } = getHtmlElements();
  connectWalletBtn.addEventListener("click", connectWallet);
  tweetForm.addEventListener("submit", submitTweetForm);
})();
