module voting_program::Voting
{
// importing signer, vector, maps and accounts in the respective line
use std::signer;
use std::vector;
use std::simple_map::{Self, SimpleMap};
use std::account;

// predefining the error message 
// if error not found
const E_NOT_OWNER: u64 = 0;
//if the program is not init 
const E_IS_NOT_INITIALIZED: u64 = 1;
//if the specific function is not init
const E_IS_INITIALIZED: u64 = 3;
// if the candidate is not init
const E_IS_INITIALIZED_WITH_CANDIDATE: u64 = 4;
//if the winner have some issue
const E_WINNER_DECLARED: u64 = 5;
// any account try to vote again and again
const E_HAS_VOTED: u64 = 6;

// There are two resouces in this program, Candiate List and Voting List. which are going to store on the voting_program address.
struct CandidateList has key {
    //taking candidate list
    candidate_list: SimpleMap<address, u64>,
    //taking candidate address
    c_list: vector<address>,
    //winner
    winner: address
}

struct VotingList has key {
    // voters mapping address and integer
    voters: SimpleMap<address, u64>
}

//adding some helper function to use throughout the code
public fun assert_is_owner(addr: address) {
    //throwing an error if parameter address is not similar to voting address that is declared on top.
    assert!(addr == @voting_program, 0);
}

public fun assert_is_initialized(addr: address) {
    // throw error if the Candiate and Voting List already exist on chain.
    assert!(exists<CandidateList>(addr), 1);
    assert!(exists<VotingList>(addr), 1);
}

public fun assert_uninitialized(addr: address) {
    // if the resources are not init then throw errors
    assert!(!exists<CandidateList>(addr), 3);
    assert!(!exists<VotingList>(addr), 3);
}

public fun assert_contains_key(map: &SimpleMap<address, u64>, addr: &address) {
    // throw errors if map already contains the given address
    assert!(simple_map::contains_key(map, addr), 2);
}

public fun assert_not_contains_key(map: &SimpleMap<address, u64>, addr: &address) {
    //throw error if the map doesn't contain the given keys
    assert!(!simple_map::contains_key(map, addr), 4);
}

// admin function that should be init by the admin only
public entry fun initialize_with_candidate(acc: &signer, c_addr: address) acquires CandidateList {
    //fetching the signer to sign transaction
    let addr = signer::address_of(acc);
    // using the helper function to check weather the addr is the admin address or not
    assert_is_owner(addr);
    // throw error if the address is not init
    assert_uninitialized(addr);
    // making an instance of the candidate List (resource) and init it.
    let c_store = CandidateList{
        candidate_list:simple_map::create(),
        c_list: vector::empty<address>(),
        winner: @0x0,
        };
        //passing these things on chain
        move_to(acc, c_store);
        // making an instance of voting list, and init it.
        let v_store = VotingList {
        voters:simple_map::create(),
        };
        //moving resources to aptos blockchain
        move_to(acc, v_store);

    // fetching the mutable resource and manipulating it
    let c_store = borrow_global_mut<CandidateList>(addr);
    //adding the candidate list to the map
    simple_map::add(&mut c_store.candidate_list, c_addr, 0);
    //pushing it in array vector
    vector::push_back(&mut c_store.c_list, c_addr);
}

//adding the candiate for the voting
public entry fun add_candidate(acc: &signer, c_addr: address) acquires CandidateList {
    // fetching the signer from the address
    let addr = signer::address_of(acc);
    // This function can only be accessed by the admin
    assert_is_owner(addr);
    // All the structs should be init before reaching this point
    assert_is_initialized(addr);
    //fetching the candidateList (struct) resource in the mutable form
    let c_store = borrow_global_mut<CandidateList>(addr);
    // give error if the winner is anyone else other than the given address
    assert!(c_store.winner == @0x0, 5);
    // taking helper functiion to make sure the index for the map exist
    assert_not_contains_key(&c_store.candidate_list, &c_addr);
    // adding the candidate list with the index
    simple_map::add(&mut c_store.candidate_list, c_addr, 0);
    //pushing in an dynamic array
    vector::push_back(&mut c_store.c_list, c_addr);
}

public entry fun vote(acc: &signer, c_addr: address, store_addr: address) acquires CandidateList, VotingList{
    // taking signer
    let addr = signer::address_of(acc);
    // making sure all the things are initlized
    assert_is_initialized(store_addr);
    // fetching the candidate list
    let c_store = borrow_global_mut<CandidateList>(store_addr);
    // fetching the voting list
    let v_store = borrow_global_mut<VotingList>(store_addr);
    //verifing the winner is none other than 0x0
    assert!(c_store.winner == @0x0, 5);
    assert!(!simple_map::contains_key(&v_store.voters, &addr), 6);
    assert_contains_key(&c_store.candidate_list, &c_addr);
    // taking the votes from the map and updating it
    let votes = simple_map::borrow_mut(&mut c_store.candidate_list, &c_addr);
    *votes = *votes + 1;
    //pushing the updated vote on map
    simple_map::add(&mut v_store.voters, addr, 1);
}

public entry fun declare_winner(acc: &signer) acquires CandidateList {
    let addr = signer::address_of(acc);
    assert_is_owner(addr);
    assert_is_initialized(addr);
    //fetching resources as mutable
    let c_store = borrow_global_mut<CandidateList>(addr);
    //checking weather if the winner is same or not
    assert!(c_store.winner == @0x0, 5);
    // taking the lenght of the array and size of the candidates
    let candidates = vector::length(&c_store.c_list);
    // adding the temporry variable
    let i = 0;
    // winner address
    let winner: address = @0x0;
    //max vote
    let max_votes: u64 = 0;

    while (i < candidates) {
        // taking the candidate list 
        let candidate = *vector::borrow(&c_store.c_list, (i as u64));
        let votes = simple_map::borrow(&c_store.candidate_list, &candidate);

        if(max_votes < *votes) {
            max_votes = *votes;
            winner = candidate;
        };
        i = i + 1;
    };

    c_store.winner = winner;
}

#[test(admin = @my_addrx)]

public entry fun test_flow(admin: signer) acquires CandidateList, VotingList {
    let c_addr = @0x1;
    let c_addr2 = @0x2;
    let voter = account::create_account_for_test(@0x3);
    let voter2 = account::create_account_for_test(@0x4);
    let voter3 = account::create_account_for_test(@0x5);
    initialize_with_candidate(&admin, c_addr);
    add_candidate(&admin, c_addr2);
    let candidate_list = &borrow_global<CandidateList>(signer::address_of(&admin)).candidate_list;
    assert_contains_key(candidate_list, &c_addr);
    assert_contains_key(candidate_list, &c_addr2);


    vote(&voter, c_addr, signer::address_of(&admin));
    vote(&voter2, c_addr, signer::address_of(&admin));
    vote(&voter3, c_addr2, signer::address_of(&admin));

    let voters = &borrow_global<VotingList>(signer::address_of(&admin)).voters;
    assert_contains_key(voters, &signer::address_of(&voter));
    assert_contains_key(voters, &signer::address_of(&voter2));
    assert_contains_key(voters, &signer::address_of(&voter3));

    declare_winner(&admin);
    let winner = &borrow_global<CandidateList>(signer::address_of(&admin)).winner;
    assert!(winner == &c_addr, 0);
}

#[test(admin = @my_addrx)]
#[expected_failure(abort_code = E_WINNER_DECLARED)]
public entry fun test_declare_winner(admin: signer) acquires CandidateList, VotingList {
    let c_addr = @0x1;
    let c_addr2 = @0x2;
    let voter = account::create_account_for_test(@0x3);
    let voter2 = account::create_account_for_test(@0x4);
    let voter3 = account::create_account_for_test(@0x5);
    initialize_with_candidate(&admin, c_addr);
    add_candidate(&admin, c_addr2);

    vote(&voter, c_addr, signer::address_of(&admin));
    vote(&voter2, c_addr, signer::address_of(&admin));
    vote(&voter3, c_addr2, signer::address_of(&admin));

    declare_winner(&admin);
    declare_winner(&admin);
}

#[test]
#[expected_failure(abort_code = E_NOT_OWNER)]

public entry fun test_initialize_with_candidate_not_owner() acquires CandidateList {
    let c_addr = @0x1;
    let not_owner = account::create_account_for_test(@0x2);
    initialize_with_candidate(&not_owner, c_addr);
}

#[test(admin = @my_addrx)]
#[expected_failure(abort_code = E_IS_INITIALIZED)]
public entry fun test_initialize_with_same_candidate(admin: signer) acquires CandidateList {
    let c_addr = @0x1;
    initialize_with_candidate(&admin, c_addr);
    initialize_with_candidate(&admin, c_addr);
}

#[test(admin = @my_addrx)]
#[expected_failure(abort_code = E_HAS_VOTED)]

public entry fun test_vote_twice(admin: signer) acquires CandidateList, VotingList {
    let c_addr = @0x1;
    let voter = account::create_account_for_test(@0x2);
    initialize_with_candidate(&admin, c_addr);
    vote(&voter, c_addr, signer::address_of(&admin));
    vote(&voter, c_addr, signer::address_of(&admin));
}

#[test(admin = @my_addrx)]
#[expected_failure(abort_code = E_IS_NOT_INITIALIZED)]

public entry fun test_vote_not_initialized(admin: signer) acquires CandidateList, VotingList {
    let c_addr = @0x1;
    let voter = account::create_account_for_test(@0x2);
    vote(&voter, c_addr, signer::address_of(&admin));
}

#[test(admin = @my_addrx)]
#[expected_failure(abort_code = E_WINNER_DECLARED)]

public entry fun test_add_candidate_after_winner_declared(admin: signer) acquires CandidateList, VotingList {
    let c_addr = @0x1;
    let c_addr2 = @0x2;
    let c_addr3 = @0x3;
    let voter = account::create_account_for_test(@0x2);
    let voter2 = account::create_account_for_test(@0x3);
    initialize_with_candidate(&admin, c_addr);
    add_candidate(&admin, c_addr2);
    vote(&voter, c_addr, signer::address_of(&admin));
    vote(&voter2, c_addr, signer::address_of(&admin));
    declare_winner(&admin);
    add_candidate(&admin, c_addr3);
}

}