const https = require('https');

// node 12-05.js

const getInputPromise = () => new Promise((resolve, reject) => {
    const options = {
	hostname: 'adventofcode.com',
	path: '/2024/day/5/input',
	headers: {
	    "Cookie": process.env.AOC_COOKIE
	}
    };
    const req = https.request(options, res => {
	const chunks = [];
	res.on('data', chunk => chunks.push(chunk));
	res.on('error', reject);
	res.on('end', () => {
	    const body = chunks.join('');
	    resolve(body);
	});
    })
    req.on('error', reject);
    req.end();
});


const parseInput = (input) => {
    const split_in = input.split("\n\n");

    return {
	ordering_rules: split_in[0].trim().split("\n").map(i => {
	    split_rule = i.split("|");
	    return {
		before: Number(split_rule[0]),
		after: Number(split_rule[1])
	    }
	}),
	page_updates: split_in[1].trim().split("\n").map(i => {
	    return i.split(",").map( (i) => {
		return Number(i);
	    });
	})
    }
}


const isCorrectlyOrdered = (rules, update_line) => {
    let isOrdered = true;

    //crazy I cant break out of a forEach
    for (let i = 0; i < rules.length; i++) {
	before_i = update_line.indexOf(rules[i].before);
	after_i = update_line.indexOf(rules[i].after);

	if(before_i >= 0 && after_i >= 0) {
	    if(after_i < before_i) {
		isOrdered = false;
		break;
	    }
	}
    }
    
    return isOrdered;
}


const order = (rules, update_line) => {
    let line = update_line;
    let sorted = false;

    while(!sorted) {
	sorted = true;
	for (let i = 0; i < rules.length; i++) {
	    before_i = line.indexOf(rules[i].before);
	    after_i = line.indexOf(rules[i].after);

	    if(before_i >= 0 && after_i >= 0) {
		if(after_i < before_i) {
		    sorted = false;
		    
		    var b = line[before_i];
                    line[before_i] = line[after_i];
		    line[after_i] = b;
		}
	    }
	}
    }

    return line;
}

// there appears to be no even page lengths
const sumMiddleElements = (updates) => {
    let middleElements = [];

    updates.forEach((update) => {
        middleElements.push(update[Math.floor(update.length / 2)]);
    });

    return middleElements.reduce((a, b) => a + b, 0);
}

getInputPromise().then((res) => {
    const parsed = parseInput(res);
    const correctly_ordered = parsed.page_updates.filter( (i) => {
	return isCorrectlyOrdered(parsed.ordering_rules, i);
    });
    
    console.log("Part 1:", sumMiddleElements(correctly_ordered));


    const unordered = parsed.page_updates.filter( (i) => {
	return !isCorrectlyOrdered(parsed.ordering_rules, i);
    });
    const then_ordered = unordered.map( (line) => {
	return order(parsed.ordering_rules, line);
    });
    console.log("Part 2:", sumMiddleElements(then_ordered));    
});
