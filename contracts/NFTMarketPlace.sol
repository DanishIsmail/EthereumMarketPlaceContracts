// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract NFTMarketPlace is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
   
   //structure to store the listing nfts
    struct ListingItemPublic{
        uint256 tokenId;
        address payable ownerAddress;
        address payable seller;
        uint256 price;
        bool isListed;
    }

    //contracts events
    event NFTListed(uint256 indexed tokenId, address owner, address seller,uint256 price);
    event NFTRemoved(uint256 indexed tokenId, address owner, address seller);

    //state variables
    address payable _owner;
    uint256 private _marketplaceCut;

    mapping(address => address) private _admins;
    mapping(uint256 => ListingItemPublic) private listedNFTs;

    constructor() ERC721("NFTMarketplace", "NFTS") payable{
        _marketplaceCut = 0.0001 ether;
        _owner = payable(msg.sender);
        _admins[msg.sender] = msg.sender;
    }

    // modifier
    modifier onlyOwners() {
        require(_admins[_owner] == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // member functions
    function updateMarketplaceCut(uint256 marketplaceCut_) public onlyOwner {
        _marketplaceCut = marketplaceCut_;
    }
    
    function getMarketplaceCut() public view returns (uint256) {
        return _marketplaceCut;
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }
    function addOwners(address newOwner_) public onlyOwner{
        require(newOwner_ != address(0), "Address should not be 0");
        require(_admins[_owner] != newOwner_, "Address already exist");
        _admins[_owner]= newOwner_;
    }

    function isOwners(address owner_)public view returns(bool){
        return _admins[_owner] == owner_;
    }

     function mintNFT(string memory tokenURI) public payable returns (uint) {
        //  uint256 price
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        // listedNFTForSale(newTokenId, price);

        return newTokenId;
    }

    function listedNFTForSale(uint256 tokenId, uint256 price) public {
        require(price > 0, "please provide valid price");

        listedNFTs[tokenId] = ListingItemPublic(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);

        emit NFTListed(tokenId, address(this), msg.sender, price);
    }

    function unListedNFTForSale(uint256 tokenId) public {
        require(tokenId >= 0, "token id is invalid");

        address seller = listedNFTs[tokenId].seller;
        require (seller == msg.sender, "you don not have rights to unlist other user nft");
        delete listedNFTs[tokenId];
        _transfer(address(this), msg.sender, tokenId);

        emit NFTRemoved(tokenId, address(this), msg.sender);
    }

    function getAllListedNFTs() public view returns (ListingItemPublic[] memory) {
        uint nftCount = _tokenIds.current();
        ListingItemPublic[] memory NFTs = new ListingItemPublic[](nftCount);
        uint currentIndex = 0;
        uint currentId;
        for(uint i=0;i<nftCount;i++){
            currentId = i + 1;
            ListingItemPublic storage currentItem = listedNFTs[currentId];
            NFTs[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return NFTs;
    }

     function getlistedNFTsByUser() public view returns (ListingItemPublic[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;
        for(uint i=0; i < totalItemCount; i++){
            if(listedNFTs[i+1].ownerAddress == msg.sender || listedNFTs[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        ListingItemPublic[] memory tokens = new ListingItemPublic[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(listedNFTs[i+1].ownerAddress == msg.sender || listedNFTs[i+1].seller == msg.sender) {
                currentId = i+1;
                ListingItemPublic storage currentItem = listedNFTs[currentId];
                tokens[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return tokens;
    }

    function purchaseNFTFromSale(uint256 tokenId) public payable {
        uint price = listedNFTs[tokenId].price;
        address seller = listedNFTs[tokenId].seller;
        require(msg.value >= price, "Please submit the requied price in order to purchase the given nft");
        _removeForomSale(tokenId);
        _itemsSold.increment();
        _transfer(payable(address(this)), payable(msg.sender), tokenId);
        approve(payable(address(this)), tokenId);
        uint amount = msg.value - _marketplaceCut;
        
        payable(_owner).transfer(_marketplaceCut);
        payable(seller).transfer(amount);
    }

    function _removeForomSale(uint256 tokenId) internal {
        require(tokenId >= 0, "token id is invalid");
        delete listedNFTs[tokenId];
    }


}