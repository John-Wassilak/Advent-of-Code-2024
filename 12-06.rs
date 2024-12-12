use std::io::Read;
use std::error::Error;
use std::str::Chars;
use std::env;

// Super good intro to rust, but not proud of the output
// I painted myself into a corner with the definition of a 'loop'
// during part 2, then had to bail.
// Ended up falling back on some imperative, non-functional patterns to finish
// I'm sure if I came back after a while I could make it more functional and concise.
//
// add `reqwest = { version = "0.12", features = ["blocking"] }` as a cargo dep
//
// run with `cargo run`
// I don't plan to save things in the needed folder stucture, so you'll need
// to init that before running

fn get_input() -> Result<String, Box<dyn Error>> {
    let client = reqwest::blocking::Client::new();
    let mut res = client
	.get("https://adventofcode.com/2024/day/6/input")
	.header("Cookie", env::var("AOC_COOKIE")?)
	.send()?;
    let mut body = String::new();
    res.read_to_string(&mut body)?;

    return Ok(body);
}


// i suspect there's something better than collect.collect
fn parse_input(input: String) -> Vec<Vec<char>> {
    return input.lines()
	.map(str::chars).map(Chars::collect)
	.collect();
}


#[derive(Debug)]
enum Status {
    Done,
    NotDone,
    Loop
}


// mutates given array
fn iterate_position(input: &mut Vec<Vec<char>>) -> Status {
    for (i, row) in input.iter().enumerate() {
        for (j, col) in row.iter().enumerate() {
	    match col {                           // find guy
		'^' => if i == 0 {                // if at top
		    input[i][j] = 'X';            // set current loc to X
		    return Status::Done;          // say we're done
		} else if input[i-1][j] == '#' {  // if obsticle above
		    input[i][j] = '>';            // rotate 90
		    return Status::NotDone;       // say continue
		} else {                          // otherwise move up
		    input[i][j] = 'X';            // set current loc to X
		    input[i-1][j] = '^';          // set above to guy
		    return Status::NotDone;       // say continue
		},

		'>' => if j == row.len() - 1 {    // if at most right
		    input[i][j] = 'X';            // set current loc to X
		    return Status::Done;          // say we're done
		} else if input[i][j+1] == '#' {  // if obsticle to right
		    input[i][j] = 'V';            // rotate 90
		    return Status::NotDone;       // say continue
		} else {                          // otherwise move right
		    input[i][j] = 'X';            // set current loc to X
		    input[i][j+1] = '>';          // set right to guy
		    return Status::NotDone;       // say continue
		},

		'V' => if i == input.len() - 1 {  // if at bottom
		    input[i][j] = 'X';            // set current loc to X
		    return Status::Done;          // say we're done
		} else if input[i+1][j] == '#' {  // if obsticle below
		    input[i][j] = '<';            // rotate 90
		    return Status::NotDone;       // say continue
		} else {                          // otherwise move down
		    input[i][j] = 'X';            // set current loc to X
		    input[i+1][j] = 'V';          // set below to guy
		    return Status::NotDone;       // say continue
		},
		
		'<' => if j == 0 {                // if at left
		    input[i][j] = 'X';            // set current loc to X
		    return Status::Done;          // say we're done
		} else if input[i][j-1] == '#' {  // if obsticle left
		    input[i][j] = '^';            // rotate 90
		    return Status::NotDone;       // say continue
		} else {                          // otherwise move down
		    input[i][j] = 'X';            // set current loc to X
		    input[i][j-1] = '<';          // set left to guy
		    return Status::NotDone;       // say continue
		},
		
		_ => continue,  //irrelevant char, keep looping
	    }
	}
    }

    // guy not found?
    return Status::Done;
}


fn run_scenario(input: &mut Vec<Vec<char>>) -> Status {
    let mut counter = 0;
    while counter < 10_000 {
	match iterate_position(input) {
	    Status::Done => return Status::Done,
	    _ => counter += 1,
	}
    }
    return Status::Loop;
}


fn part_2_scenario(input: Vec<Vec<char>>) {
    let mut counter = 0;
    for (i, row) in input.iter().enumerate() {
        for (j, col) in row.iter().enumerate() {
	    if !['^', '>', 'v', '<', '#'].contains(col) { // skip invalid scenarios
		println!("on {} {}", i, j);  // status since it's taking a while
		let mut new_input = input.clone();
		new_input[i][j] = '#';
		match run_scenario(&mut new_input) {
		    Status::Loop => counter += 1,
		    _ => continue
		}
	    }
	}
    }
    println!("part2: {}", counter);
}
			

fn main() {
    let input = get_input();

    if let Ok(i) = input {
	let parsed = parse_input(i);

	let mut part_1_input = parsed.clone();

	match run_scenario(&mut part_1_input) {
	    Status::Done => {
	        let countx = part_1_input.into_iter()
		    .map(|x| x.into_iter().collect())
		    .collect::<Vec<String>>().join("")
		    .chars().filter(|c| *c == 'X')
		    .collect::<String>().len();

	        println!("part1: {:?}", countx)
	    },
	    _ => println!("error processing input"),
	}
	part_2_scenario(parsed);
    } else {
	println!("error getting input");
    }
    
}
