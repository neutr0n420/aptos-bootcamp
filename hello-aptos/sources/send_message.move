module send_message::hello {
    use std::string:: {utf8, String};
    use std::signer;
    use aptos_framework::account;

    // structs
    struct Message has key{
        my_msg: String
    }
    // functions
    public entry fun message_fun(account:&signer, msg:String) acquires Message{
        // taking the wallet address of the user
        let signer_address = signer::address_of(account);
        // checking if the `Message Struct` exists on the account address or not
        if(!exists<Message>(signer_address)){
            // if it dose not exit, making a instance of message struct.
            let message = Message{
                my_msg: msg
            };
            // using move_to function we are pushing the instance on chain.
            move_to(account, message);
        }
        // if the `Message` sturct already exists, we will update the struct and adding the new message in the struct

        else{
            // fetching the struct from chain in the mutable from, so that we can update the struct.
            let message = borrow_global_mut<Message>(signer_address);
            // update the message struct.
            message.my_msg = msg;
        }
    }
    // tests
    #[test(admin = @0xabc)]
    public entry fun test_message(admin: signer) acquires Message{
        account::create_account_for_test(signer::address_of(&admin));
        message_fun(&admin, utf8(b"This is the first message"));
        message_fun(&admin, utf8(b"This is the updated message"));

        let message = borrow_global<Message>(signer::address_of(&admin));
        assert!(message.my_msg == utf8(b"This is the updated message"), 10);
    }
}