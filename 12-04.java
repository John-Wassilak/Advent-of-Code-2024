import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

// javac 12-04.java && java AOC_1204

class AOC_1204 {

    static ArrayList<String> getInput() throws Exception {
	URL url = new URL("https://adventofcode.com/2024/day/4/input");
	HttpURLConnection MyConn = (HttpURLConnection) url.openConnection();
	MyConn.setRequestMethod("GET");
	MyConn.setRequestProperty("Cookie", System.getenv("AOC_COOKIE"));
        BufferedReader in = new BufferedReader(new InputStreamReader(MyConn.getInputStream()));
	ArrayList<String> response = new ArrayList<String>();
	String inputLine;

        while ((inputLine = in.readLine()) != null) {
            response.add(inputLine);
        }
        in.close();

	return response;
    }

    
    public static void main(String[] args) throws Exception {
	PuzzleMatrix input = new PuzzleMatrix(getInput());
	System.out.println("Part 1: " + input.totalXMAS());
	System.out.println("Part 2: " + input.totalXmasPart2());
    }
}

class PuzzleMatrix {
    int ROWS;
    int COLS;
    char [][] input_array;

    PuzzleMatrix(ArrayList<String> input) {
	this.ROWS = input.size();
	this.COLS = 0;

	for(int i = 0; i < this.ROWS; i++) {
	    if(input.get(i).length() > this.COLS) {
		this.COLS = input.get(i).length();
	    }
	}

	this.input_array = new char [ROWS][COLS];

	for(int i = 0; i < this.ROWS; i++) {
	    this.input_array[i] = input.get(i).toCharArray();
	}
    }

    int totalXMAS() {
	int total = 0;
	
	for(int row = 0; row < this.ROWS; row++) {
	    for(int col = 0; col < this.COLS; col++) {
		if(input_array[row][col] == 'X') {
		    total += countXMAS(row, col);
		}
	    }
	}

	return total;
    }

    int totalXmasPart2() {
	int total = 0;
	
	for(int row = 0; row < this.ROWS; row++) {
	    for(int col = 0; col < this.COLS; col++) {
		if(input_array[row][col] == 'A' &&
		   isXmasPart2(row, col)) {
		       total++;
		}
	    }
	}

	return total;
    }

    // per usual, there's bound to be a more clever way, but it only
    // needs to run once...
    // using ints rather than bools since I'm not sure if multiple instances
    // from one 'x' count....I think they do
    int countXMAS(int row, int column) {
	return (countXMASDirection(row, column, 0, 1) + // horiz right
		countXMASDirection(row, column, 0, -1) + // horiz left
		countXMASDirection(row, column, -1, 0) + // vert up
		countXMASDirection(row, column, 1, 0) + // vert down
		countXMASDirection(row, column, -1, 1) + // diag ur
		countXMASDirection(row, column, 1, 1) + // diag dr
		countXMASDirection(row, column, -1, -1) + // diag ul
		countXMASDirection(row, column, 1, -1)); // diag dl
    }

    // -1 == up or left, 0 == nothing, +1 = down or right
    private int countXMASDirection(int row, int column, int row_direction,
				  int col_direction) {
   
        // check if there's room
	if((row_direction < 0 && row < 3) ||                 // up
	   (row_direction > 0 && row > (this.ROWS - 4)) ||   // down
	   (col_direction < 0 && column < 3) ||              // left
	   (col_direction > 0 && column > (this.COLS - 4))) { // right
	    return 0;
	    
	    // check if xmas
	} else if(this.input_array[row][column] == 'X' &&
		  this.input_array[row + (1 * row_direction)][column + (1 * col_direction)] == 'M' &&
		  this.input_array[row + (2 * row_direction)][column + (2 * col_direction)] == 'A' &&
		  this.input_array[row + (3 * row_direction)][column + (3 * col_direction)] == 'S') {
	    return 1;
	} else {
	    return 0;
	}
    }

    // test from the center 'A' char. Again, just bruteforcing...
    private boolean isXmasPart2(int row, int column) {

	// check if there's room, and this is an 'A:
	if((row > 0 && row < (this.ROWS - 1)) &&
	   (column > 0 && column < (this.COLS -1)) &&
	   (this.input_array[row][column] == 'A')) {

	    // diag bottom left to upper right
	    if ((this.input_array[row+1][column-1] == 'M' &&
		 this.input_array[row-1][column+1] == 'S') ||
		(this.input_array[row+1][column-1] == 'S' &&
		 this.input_array[row-1][column+1] == 'M')) {

		// diag top left to bottom right
   	        if ((this.input_array[row-1][column-1] == 'M' &&
		     this.input_array[row+1][column+1] == 'S') ||
		    (this.input_array[row-1][column-1] == 'S' &&
		     this.input_array[row+1][column+1] == 'M')) {
		    return true;
		} else { // not top l to bottom r
		    return false;
		}
	    } else { // not bottom l to upper r
		return false;
	    }
	} else { // no room, or not 'A'
	    return false;
	}
    }
}
