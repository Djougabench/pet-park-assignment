//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PetPark is Ownable {
    event Added(AnimalType indexed _animalType, uint256 _count);
    event Borrowed(AnimalType indexed _animalType);
    event Returned(AnimalType indexed _animalType);
    event profileCreated(BorrowerProfile indexed newProfile);

    modifier validAnimal(AnimalType _animalType, string memory errorMessage) {
        require(_animalType != AnimalType.None, errorMessage);

        _;
    }

    BorrowerProfile[] public borrowersProfilesList;

    struct BorrowerProfile {
        address borrowerAddress;
        uint256 age;
        Gender gender;
        AnimalType animalType;
    }

    enum AnimalType {
        None,
        Fish,
        Cat,
        Dog,
        Rabbit,
        Parrot
    }

    enum Gender {
        Male,
        Female
    }

    mapping(AnimalType => uint256) public animalCounts;
    mapping(address => BorrowerProfile) public borrowerProfiles;

    function add(
        AnimalType _animal,
        uint256 _count
    ) external onlyOwner validAnimal(_animal, "Invalid animal") {
        animalCounts[_animal] += _count;
        emit Added(_animal, _count);
    }

    function borrow(
        uint256 _age,
        Gender _gender,
        AnimalType _animalType
    ) external validAnimal(_animalType, "Invalid animal type") {
        require(_age > 0, "Age can not be zero");

        BorrowerProfile memory profile = borrowerProfiles[msg.sender];

        if (profile.age == 0) {
            borrowerProfiles[msg.sender] = BorrowerProfile({
                borrowerAddress: msg.sender,
                age: _age,
                gender: _gender,
                animalType: AnimalType.None
            });
        } else {
            require(profile.age == _age, "Invalid Age");
            require(profile.gender == _gender, "Invalid Gender");
        }

        require(profile.animalType == AnimalType.None, "Already adopted a pet");

        if (_gender == Gender.Male) {
            require(
                _animalType == AnimalType.Dog || _animalType == AnimalType.Fish,
                "Invalid animal for men"
            );
        } else if (_gender == Gender.Female) {
            require(
                _age >= 40 || _animalType != AnimalType.Cat,
                "Invalid animal for women under 40"
            );
        }

        require(animalCounts[_animalType] > 0, "Selected animal not available");

        animalCounts[_animalType]--;

        BorrowerProfile memory newProfile = BorrowerProfile({
            borrowerAddress: msg.sender,
            gender: _gender,
            age: _age,
            animalType: _animalType
        });

        borrowerProfiles[msg.sender] = newProfile;

        borrowersProfilesList.push(newProfile);

        emit Borrowed(_animalType);
        emit profileCreated(newProfile);
    }

    function giveBackAnimal() external {
        AnimalType borrowedAnimalType = borrowerProfiles[msg.sender].animalType;
        require(borrowedAnimalType != AnimalType.None, "No borrowed pets");
        borrowerProfiles[msg.sender].animalType = AnimalType.None;
        animalCounts[borrowedAnimalType]++;
        borrowersProfilesList.pop();

        emit Returned(borrowedAnimalType);
    }

    function theAnimalCounts(
        AnimalType _animalType
    ) external view returns (uint256) {
        return animalCounts[_animalType];
    }

    function animalTypeOfBorrower() external view returns (AnimalType) {
        return borrowerProfiles[msg.sender].animalType;
    }
}
