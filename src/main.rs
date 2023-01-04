use std::io;
use std::io::prelude::*;
use std::fs::File;
use std::str;
use std::os::unix::prelude::FileExt;
use lazy_static::lazy_static;

use regex::Regex;

// https://rust-lang-nursery.github.io/rust-cookbook/text/string_parsing.html


fn main()  -> io::Result<()> {
    let derp = "1-0:1.8.0(00006095.826*kWh)";
    lazy_static! {
        static ref RE: Regex = Regex::new(r"^[0-9]-[0-9]:([0-9]+.[0-9]+.[0-9]+)\((.+)\)").unwrap();
    }

    println!("'{:?}'", derp);
    let mut f = File::open("/home/bitfox/aidon/cutecom.log").unwrap();
    
    //loop {
        let mut buffer = [0; 1000];
        f.read(&mut buffer)?;
        match f.read(&mut buffer) {
            Ok(_) => {
                if buffer.len() != 0 {
                    let lines = str::from_utf8(&buffer).unwrap();
                    for line in lines.lines() {
                        let len = line.len();
                        if len > 20 {
                            //println!("{}", &line[0..len]);
                            for cap in RE.captures_iter(line) {
                                //println!("{:?}",cap);
                                println!("Obis: {} val: {}", &cap[1], &cap[2]);
                            }
                        }
                    }
                }
            },
            Err(_) => {println!("ERRORI")}
        }
    //}
    Ok(())
}
