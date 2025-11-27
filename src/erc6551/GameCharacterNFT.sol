// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GameCharacterNFT
 * @notice NFT representing game characters
 * @dev Each character will have its own Token Bound Account
 */
contract GameCharacterNFT is ERC721, Ownable {
    // Counter for token IDs
    uint256 private _nextTokenId;

    // Registry and account implementation
    address public registry;
    address public accountImplementation;

    // Character metadata
    struct CharacterData {
        string name;
        uint256 level;
        uint256 experience;
    }

    mapping(uint256 => CharacterData) public characters;

    // Events
    event CharacterMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string name,
        address tbaAddress
    );

    event CharacterLeveledUp(uint256 indexed tokenId, uint256 newLevel);

    constructor(
        address _registry,
        address _accountImplementation
    ) ERC721("Game Character", "CHAR") Ownable(msg.sender) {
        registry = _registry;
        accountImplementation = _accountImplementation;
        _nextTokenId = 1;
    }

    /**
     * @notice Mint a new character
     * @param to Character owner
     * @param characterName Character's name
     * @return tokenId The minted token ID
     * @return tbaAddress The Token Bound Account address
     */
    function mintCharacter(
        address to,
        string memory characterName
    ) external returns (uint256 tokenId, address tbaAddress) {
        tokenId = _nextTokenId++;

        // Mint the NFT
        _safeMint(to, tokenId);

        // Set character data
        characters[tokenId] = CharacterData({
            name: characterName,
            level: 1,
            experience: 0
        });

        // Create Token Bound Account for this character
        tbaAddress = _createTBA(tokenId);

        emit CharacterMinted(to, tokenId, characterName, tbaAddress);
    }

    /**
     * @notice Create Token Bound Account for a character
     */
    function _createTBA(uint256 tokenId) internal returns (address) {
        // Call registry to create account
        (bool success, bytes memory result) = registry.call(
            abi.encodeWithSignature(
                "createAccount(address,uint256,address,uint256,uint256,bytes)",
                accountImplementation,
                block.chainid,
                address(this),
                tokenId,
                0, // salt
                "" // no init data
            )
        );

        require(success, "TBA creation failed");
        return abi.decode(result, (address));
    }

    /**
     * @notice Get Token Bound Account address for a character
     */
    function getCharacterAccount(
        uint256 tokenId
    ) public view returns (address) {
        (bool success, bytes memory result) = registry.staticcall(
            abi.encodeWithSignature(
                "account(address,uint256,address,uint256,uint256)",
                accountImplementation,
                block.chainid,
                address(this),
                tokenId,
                0 // salt
            )
        );

        require(success, "Account query failed");
        return abi.decode(result, (address));
    }

    /**
     * @notice Level up character (costs experience)
     */
    function levelUp(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        CharacterData storage char = characters[tokenId];

        // Simple leveling: 100 XP per level
        uint256 requiredXP = char.level * 100;
        require(char.experience >= requiredXP, "Not enough XP");

        char.experience -= requiredXP;
        char.level++;

        emit CharacterLeveledUp(tokenId, char.level);
    }

    /**
     * @notice Add experience to character
     */
    function addExperience(uint256 tokenId, uint256 xp) external onlyOwner {
        characters[tokenId].experience += xp;
    }

    /**
     * @notice Get character info
     */
    function getCharacter(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory name,
            uint256 level,
            uint256 experience,
            address tbaAddress
        )
    {
        CharacterData memory char = characters[tokenId];
        return (
            char.name,
            char.level,
            char.experience,
            getCharacterAccount(tokenId)
        );
    }
}
