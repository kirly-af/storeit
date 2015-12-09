extern crate hyper;
extern crate std;
extern crate regex;

use hyper::client::Response;
use hyper::header::Connection;
use hyper::error::Error;
use regex::Regex;

use std::io::Read;
use user;
use api;
use serialize;

// time between each ping sent to a user in seconds
static PING_TIME : i8 = 1;

fn build_url(ip: &str, path: &str, client_port: &str) -> String {

    "http://".to_string() + &ip + ":".as_ref() + client_port + path
}

pub fn get(ip: &std::net::SocketAddr, path: &str, port: &str)
-> Result<Response, Error> {

    let mut ip = ip.to_string();
    ip.truncate(9);

    let url = build_url(&ip, path, port);

    debug!("url is {}", url);

    let client = hyper::Client::new();

    client.get(&url)
        .send()
}

// TODO: merge this with the post function
pub fn put(ip: &std::net::SocketAddr, path: &str, body_content: &str, port: &str)
-> Result<Response, Error> {

    let mut ip = ip.to_string();
    ip.truncate(9);

    let url = build_url(&ip, path, port);
    let client = hyper::Client::new();

    client.put(&url)
        .body(body_content)
        .send()
}

pub fn post(ip: &std::net::SocketAddr, path: &str, body_content: &str, port: &str)
-> Result<Response, Error> {


    let mut ip = ip.to_string();
    ip.truncate(9);

    let url = build_url(&ip, path, port);

    let client = hyper::Client::new();

    debug!("posting at {}", url);

    client.post(&url)
        .body(body_content)
        .send()
}

#[allow(unused)]
pub fn parse_post(mut request: hyper::server::Request,
                  username: &str,
                  sdata: &serialize::ServerData) {

    let api_uri : String = match request.uri {
        hyper::uri::RequestUri::AbsolutePath(ref s) => String::from(s.as_ref()),
        _ => {
            error!("bad enum for request.uri");
            return;
        }
    };

    // I need an absolute url to use hyper's parsing
    let artificial_url = ["http://null/", api_uri.as_ref()].concat();

    let uri = hyper::Url::parse(&artificial_url).unwrap();

    // We get the "foo=bar" from the url
    let variable = uri.query;

    // we take everything before "?" for the path (ex: /session/join?port=1234)
    let re = Regex::new(r"(.+)\?").unwrap();
    let path = re.captures(api_uri.as_ref()).unwrap().at(1).unwrap();


    let mut request_body = String::new();

    match request.read_to_string(&mut request_body) {
        Ok(_) => (),
        Err(_) => {
            error!("oops, cannot read http request");
            return;
        }
    }

    match path {
        "/session/join" => {

            let variable = match variable {
                Some(v) => v,
                None    => {
                    error!("client did not give port in url");
                    return;
                }
            };

            //let re = Regex::new(r"^port=([:digit:]+)$").unwrap();
            //let client_port = re.captures(variable.as_ref()).unwrap().at(0).unwrap().parse::<i16>().unwrap();

            let client_port = variable;

            debug!("client port is : {}", client_port);

            match serialize::decode_tree(&request_body) {
                Err(e) => error!("POST request is invalid: {}", e),
                Ok(ref r) => {
                    api::connect_user(username, &sdata.users,
                                      &request, r, &client_port, sdata);
                }

            }
        }
        other     => error!("Request has bad or unimplemented API url: {}", other),
    }
}
