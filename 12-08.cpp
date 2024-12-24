#include <iostream>
#include <string>
#include <sstream>
#include <curl/curl.h>
#include <vector>
using namespace std;

/*
  I kinda wish I hated this more than I do...

  So you're telling me, if I scope something (allocate on stack), any further
  heap alloc that it does get's cleaned up automatically, once it's out of scope...

  That seems pretty nice...

  I guess, the way I'm writing this (returning objects) forces a lot of 'copy's
  to happen (obj/memory from function is copied to caller, not just returning
  a pointer). The compiler can evidently optimize that, but more importantly,
  I'm not looking for performance. I guess if I was I'd pass resources into
  helper functions, rather than 'create and return'

  running:
   gcc 12-08.c -o 12-08 -lcurl && ./12-08
   or
   gcc -DDEBUG -g 12-08.c -o 12-08 -lcurl && \
   valgrind --trace-children=yes --track-fds=yes	       \
            --track-origins=yes --leak-check=full --show-leak-kinds=all \
            -s ./12-08
 */


static size_t WriteCallback(void *contents, size_t size,
			    size_t nmemb, void *userp) {
    ((string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}


string get_input() {
  CURL *curl;
  CURLcode res;
  string inputBuffer;

  curl = curl_easy_init();
  if(curl) {
    curl_easy_setopt(curl, CURLOPT_URL,
		     "https://adventofcode.com/2024/day/8/input");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &inputBuffer);
    curl_easy_setopt(curl, CURLOPT_COOKIE, getenv("AOC_COOKIE"));
    res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
  }

  return inputBuffer;
}


// I could have just done c-style char[][],
//    but I figure I should learn vectors
vector<vector<char>> parse_input(const string& input) {
  istringstream f(input);
  string line;
  vector<vector<char>> matrix;

  while (getline(f, line)) {
    vector<char> data(line.begin(), line.end());
    matrix.push_back(data);
  }

  return matrix;
}

// this could probably be more efficient by saving x,y or something
// but i figure it's just fine if I be visual and create a second
// matrix for the antinodes and just count them afterwards
vector<vector<char>> generate_antinodes(const vector<vector<char>>& input, bool isP2) {
  vector<vector<char>> antinodes;

  // duplicate our input matrix, to maintain dimensions
  copy(input.begin(), input.end(), back_inserter(antinodes));


  // loop over input matrix
  for (int row_i = 0; row_i < input.size(); row_i++) {
    for (int col_i = 0; col_i < input[row_i].size(); col_i++) {

      // if antenna found
      if(input[row_i][col_i] != '.') {
	int similar_antennas_in_line = 0;

	// loop through matrix again to find matching antenna
	for (int in_row_i = 0; in_row_i < input.size(); in_row_i++) {
	  for (int in_col_i = 0; in_col_i < input[in_row_i].size(); in_col_i++) {

	    // if not the same spot, and the same freq
	    if(!(in_row_i == row_i && in_col_i == col_i) &&
	       input[in_row_i][in_col_i] == input[row_i][col_i]) {
	      similar_antennas_in_line++;

	      // find relationship
	      int row_diff = in_row_i - row_i;
	      int col_diff = in_col_i - col_i;

	      // find antinode
	      int an_row = in_row_i + row_diff;
	      int an_col = in_col_i + col_diff;

	      // P1, add antinode...if within bounds
	      if(!isP2 && (an_row >= 0 && an_row < input.size()) &&
		 (an_col >= 0 && an_col < input[an_row].size())) {
		antinodes[an_row][an_col] = '#';
	      } else { //p2

		// see if this node is alread in line with 2
		if(similar_antennas_in_line > 1) {
		  antinodes[row_i][col_i] = '#';
		}

		// keep adding antinodes in line until out of bounds
		while((an_row >= 0 && an_row < input.size()) &&
		      (an_col >= 0 && an_col < input[an_row].size())) {
		  antinodes[an_row][an_col] = '#';

		  an_row += row_diff;
		  an_col += col_diff;
		}
	      }
	    } 
	  }
	}
      }   
    }
  }
  
  return antinodes;
}


int count_antinodes(vector<vector<char>>& antinodes) {
  int count = 0;

  for (auto i: antinodes) {
    for (auto j: i) {
      if (j == '#') {
	count++;
      }
    }
  }
  
  return count;
}


int main(void) {
  string inputBuffer = get_input();
  vector<vector<char>> matrix = parse_input(inputBuffer);
  vector<vector<char>> antinodes = generate_antinodes(matrix, false);
  vector<vector<char>> antinodes_p2 = generate_antinodes(matrix, true);

  cout << "Part 1: " << count_antinodes(antinodes) << endl;
  cout << "Part 2: " << count_antinodes(antinodes_p2) << endl;
  return 0;
}
