// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//INTERNAL IMPORT FOR NFT OPENZEPPELIN
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721 {
    
    private uint256 _tokenId;
    private uint256 _itemsSold;
    uint256 listingPrice = 0.0025 ether;

    address payable owner;

    mapping (uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint price,
        bool sold
    );
    modifier onlyOwner {
        require(msg.sender == owner,"Only the owner of the marketplace can change the price");
        _;
    }
    constructor() ERC721("NFT Token", "MYNFT") {
        owner == payable(msg.sender);
    }
    
    function updateListingPrice(uint256 _listingPrice)  public payable onlyOwner{
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns(uint256){
        return listingPrice;
    }

    function createToken(string memory tokenUri, uint256 price) public payable return(uint256){
        _tokenId = _tokenId+1;

        uint256 newTokenId = _tokenId;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId,tokenUri);

        createMarketItem(newTokenId,price);

        return newTokenId;
    }

    //CREATING MARKET ITEM
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be greater than 0!");
        require(msg.value == listingPrice, "Price must be equal to listing price!");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false,
        );
        _transfer(msg.sender,address(this),tokenId);

        emit idMarketItemCreated(tokenId,msg.sender,address(this),price,false);
    }

    //UPDATING PRICE OF MARKET ITEM AND SELLING AGAIN
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(idMarketItem[tokenId]==msg.sender, "Only item owner can perform this operation!");
        require(msg.value == listingPrice, "Price must be equal to listing price!")

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold = _itemsSold - 1;

        _transfer(msg.sender,address(this),tokenId);
    }

    //SELLING MARKET ITEM
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;

        require(msg.value == price, "Please submit asking price!");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemsSold = _itemsSold + 1;

        _transfer(address(this),msg.sender,tokenId);
        payable(owner).transfer(listingPrice); //COMMISION FOR OWNER OF WEB SITE
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    //GETTING UNSOLD NFT DATA
    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenId;
        uint256 unSoldItemCount = _tokenId - _itemsSold;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for(uint256 i = 0; i<itemCount;i++){
            if(idMarketItem[i+1].owner == address(this)){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex = currentIndex + 1;
            }
        }
        return items;
    }

   //PURCHASE OF MARKET ITEM
   function fetchMyNFT() public view returns(MarketItem[] memory){
    uint256 totalCount = _tokenId;
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for(uint256 i = 0; i<totalCount; i++){
        if(idMarketItem[i+1].owner == msg.sender){
            itemCount = itemCount + 1;
        }
    }
    MarketItem [] memory items = new MarketItem[](itemCount);
    for(uint256 i = 0; i<totalCount; i++){
        if(idMarketItem[i+1].owner == msg.sender){
        uint256 currentId = i+1;
        MarketItem storage currentItem = idMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex = currentIndex + 1;
        }
    }
    return items;
   }

   //SINGLE USER ITEMS
    function fetchItemsListed()public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenId;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i = 0; i<totalCount; i++){
        if(idMarketItem[i+1].seller == msg.sender){
            itemCount = itemCount + 1;
        }
    }
     MarketItem storage items = idMarketItem[itemCount];
    for(uint256 i = 0; i<totalCount; i++){
        if(idMarketItem[i+1].seller == msg.sender){
        uint256 currentId = i+1;
        MarketItem storage currentItem = idMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex = currentIndex + 1;
        }
    }
    return items;
    }

}

