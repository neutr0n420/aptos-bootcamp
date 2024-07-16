module send_message::hello {
    use std::string::{utf8, String};
    use std::signer;
    use aptos_framework::account;

// Structs
struct Message has key {
    my_msg: String
}

//functions
public entry fun message_fun(account: &signer, msg: String) acquires Message {
    // empty check
    assert!(!String::is_empty(&msg), 1); // 1 is the error code

    let signer_address = signer::address_of(account);
    if(!exists<Message>(signer_address)) {
        let message = Message {
            my_msg: msg
        };
// using move_to function to push it in the chain
        move_to(account, message)
    }

    else {
        // fetching the struct from chain and mutate the data
        let message = borrow_global_mut<Message>(signer_address);
        message.my_msg = msg;
    }
}

// tests
}