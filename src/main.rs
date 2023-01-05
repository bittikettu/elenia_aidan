use std::io::{self, Write};
use std::time::Duration;
use lazy_static::lazy_static;
use std::io::prelude::*;
use regex::Regex;
use std::str;
use chrono::{NaiveDate, NaiveTime, NaiveDateTime};

fn main() {
    lazy_static! {
        static ref RE: Regex = Regex::new(r"^[0-9]-[0-9]:([0-9]+.[0-9]+.[0-9]+)\((.+)\)").unwrap();
    }
    let ports = serialport::available_ports().expect("No ports found!");
    for p in ports {
        println!("{}", p.port_name);
    }

    let mut port = serialport::new("/dev/ttyUSB0", 115_200)
    .timeout(Duration::from_millis(10))
    .open().expect("Failed to open port");

    let mut serial_buf: Vec<u8> = vec![0; 1000];

    loop {
        match port.read(serial_buf.as_mut_slice()) {
            Ok(t) => {
                match str::from_utf8(&serial_buf[..t]) {
                    Ok(lines) => {
                        for line in lines.lines() {
                            let len = line.len();
                            if len > 5 {
                                for cap in RE.captures_iter(line) {
                                    if cap[2].contains("*") {
                                        //println!("Obis: {} val: {}", &cap[1], &cap[2]);

                                        let val: Vec<&str> = cap[2].split("*").collect();
                                        //println!("Obis:{} val:{} {}", &cap[1], val[0].parse::<f32>().unwrap(),val[1]);
                                    }
                                    else {
                                        let yy = &cap[2][..2].parse::<i32>().unwrap();
                                        let mm = &cap[2][2..4].parse::<u32>().unwrap();
                                        let dd = &cap[2][4..6].parse::<u32>().unwrap();
                                        let hour = &cap[2][6..8].parse::<u32>().unwrap();
                                        let min = &cap[2][8..10].parse::<u32>().unwrap();
                                        let sec = &cap[2][10..12].parse::<u32>().unwrap();
                                        //println!("{}.{}.{} {:02}:{:02}:{:02}", dd, mm, yy+2000, hour, min, sec);
                                        let d = NaiveDate::from_ymd_opt(*yy+2000, *mm, *dd).unwrap();
                                        let t = NaiveTime::from_hms_milli_opt(*hour, *min, *sec, 0).unwrap();
                                        let dt = NaiveDateTime::new(d, t);
                                        println!("Timestamp is : {:?}", dt.timestamp());
                                    }
                                }
                            }
                        }
                    }
                    Err(_) => {}
                }

            }
            Err(ref e) if e.kind() == io::ErrorKind::TimedOut => (),
            Err(e) => eprintln!("{:?}", e),
        }
    }
}
