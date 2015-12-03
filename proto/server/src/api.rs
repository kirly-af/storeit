extern crate std;
extern crate hyper;
extern crate time;

use user;
use http;
use serialize;
use file;
use database;

use hyper::Client;
use std::thread;
use std::sync::Arc;
use std::vec::Vec;

/* user opening a session */
pub fn connect_user(username: &str, users: &user::Users,
                    request: &hyper::server::Request,
                    user_vision: &serialize::File) {

    let mut user = user::make_new_user_from_db(request, username).unwrap();
    user.process_tree(user_vision);
    println!("at end of sync, user has tree on server: {:?}", user.root);
    database::save_tree_for_user(&user.username, &user.root);
    println!("user {} has synced and been added", &user.username);
    users.add(user);
}

fn ping_failure(user: &user::User, dead: &mut Vec<String> ) {

    println!("{} failed the ping test", user.username);

    // later, do not allocate
    dead.push(String::from(user.username.as_ref()));
}

fn send_ping(users: &user::Users) {


    let mut dead_users = vec!();

    {
        // please don't unwrap this
        // in the future, optimise by only reading first, and then writing
        let mut guard = users.users_map.write().unwrap();

        for user_tuple in &mut *guard {
            println!("sending ping to user: {}", user_tuple.0);

            // TODO: use IpAddr when not nightly anymore
            match http::get(&user_tuple.1.ip, "/session/ping") {
                Err(_)      =>
                    ping_failure(&user_tuple.1, &mut dead_users),
                Ok(res) =>
                    if res.status != hyper::status::StatusCode::Ok {
                        ping_failure(&user_tuple.1, &mut dead_users);
                    } else {
                        user_tuple.1.refresh_timestamp();
                    }
            }
        }
    }


    for name in dead_users {
        users.remove(&name);
        println!("{} was disconnected", name);
    }
}

pub fn handle_ping(users: Arc<user::Users>) -> thread::JoinHandle<()> {

    let child = thread::spawn(move || {

        loop {

            // is a copy of users done here ?
            send_ping(&*users);
            std::thread::sleep_ms(1000);
        }
    });

    child
}

pub fn add_file(user: &user::User, who: file::Who,
                file: &serialize::File) {

    match who {
        file::Who::Server => {
           println!("server has registered a new file"); 
        }
        file::Who::Client => {
            // TODO: if it fails, we should try it again until it succeeds
            http::post(&user.ip,
                       "/data/tree",
                       &serialize::tree_to_json(file).unwrap(),
                      ).unwrap();
        }
    }
}

pub fn remove_file(user: &user::User, who: file::Who,
                   file: &serialize::File) {
    println!("{} REMOVE", file.path);
}

pub fn update_file(user: &user::User, who: file::Who,
                   file: &serialize::File) {
    println!("{} UPDATE", file.path);
}

