#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

// https://adventofcode.com/2024/day/1
//
// gcc 12-01.c -o 12-01 -lcurl && ./12-01
//
// or
//
// gcc -DDEBUG -g 12-01.c -o 12-01 -lcurl && \
//	 valgrind --trace-children=yes --track-fds=yes \\
//   --track-origins=yes --leak-check=full --show-leak-kinds=all \\
//   -s ./12-01


// dont judge. I just wanted to get the answers, no refactoring has been done.

///////////////////////////// GET PUZZLE INPUT ////////////////////////////////

struct MemoryStruct {
  char *memory;
  size_t size;
};

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb,
                                  void *userp) {
  size_t realsize = size * nmemb;
  struct MemoryStruct *mem = (struct MemoryStruct *)userp;

  char *ptr = realloc(mem->memory, mem->size + realsize + 1);
  if (!ptr) {
    printf("not enough memory (realloc returned NULL)\n");
    return 0;
  }

  mem->memory = ptr;
  memcpy(&(mem->memory[mem->size]), contents, realsize);
  mem->size += realsize;
  mem->memory[mem->size] = 0;

  return realsize;
}

struct MemoryStruct *pull_input() {
  CURLcode res;
  struct MemoryStruct *chunk;
  CURL *curl_handle;

  char *url = "https://adventofcode.com/2024/day/1/input";

  chunk = (struct MemoryStruct*)malloc(sizeof(struct MemoryStruct));
  chunk->memory = malloc(1); /* grown as needed by the realloc above */
  chunk->size = 0;           /* no data at this point */

  curl_global_init(CURL_GLOBAL_ALL);
  curl_handle = curl_easy_init();
  curl_easy_setopt(curl_handle, CURLOPT_URL, url);
  curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
  curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, (void *)chunk);
  curl_easy_setopt(curl_handle, CURLOPT_COOKIE, getenv("AOC_COOKIE"));

  printf("calling: %s\n", url);
  res = curl_easy_perform(curl_handle);

  if (res != CURLE_OK) {
    fprintf(stderr, "curl_easy_perform() failed: %s\n",
            curl_easy_strerror(res));
    free(chunk->memory);
    free(chunk);
    chunk = NULL;
  }

  curl_easy_cleanup(curl_handle);
  curl_global_cleanup();

  return chunk;
}

///////////////////////////// PARSE PUZZLE INPUT //////////////////////////////

struct List {
    long number;
    long freq_in_right;
    struct List *next;
};

struct PuzzleInput {
    struct List *left;
    struct List *right;
};

void free_puzzle_input(struct PuzzleInput* input) {
    struct List *next, *this;

    next = input->left;
    while(next != NULL) {
        this = next;
        next = this->next;
        free(this);
    }
    
    next = input->right;
    while(next != NULL) {
        this = next;
        next = this->next;
        free(this);
    }

    free(input);
}

void print_puzzle_input(struct PuzzleInput* input) {
    struct List *next;

    next = input->left;
    while(next != NULL) {
        printf("left: %ld\n", next->number);
        next = next->next;
    }

    next = input->right;
    while(next != NULL) {
        printf("right: %ld\n", next->number);
        next = next->next;
    }
}

struct PuzzleInput *parse_input(char *input) {
    struct PuzzleInput *parsed;
    char *line;
    char left_str[8], right_str[8];
    struct List *left_l, *right_l;
    
    parsed = (struct PuzzleInput*)malloc(sizeof(struct PuzzleInput));
    parsed->left = NULL;
    parsed->right = NULL;

    for (line = strtok(input, "\n"); line != NULL; line = strtok(NULL, "\n")) {
        memcpy(left_str, line, 5);
        left_str[5] = '\0';
        memcpy(right_str, line+8, 5);
        right_str[5] = '\0';
        
        left_l = (struct List*)malloc(sizeof(struct List));
        right_l = (struct List*)malloc(sizeof(struct List));
        
        left_l->number = atol(left_str);
        left_l->next = parsed->left;
        parsed->left = left_l;
        
        right_l->number = atol(right_str);
        right_l->next = parsed->right;
        parsed->right = right_l;
    }

    return parsed;
}

///////////////////////////// SORT PUZZLE INPUT //////////////////////////////

void swap(struct List *a, struct List *b) {  
    long temp = a->number;
    a->number = b->number;
    b->number = temp;
}

void bubbleSort(struct List *start) {  
    int swapped;
    struct List *ptr1;  
    struct List *lptr = NULL;  
  
    /* Checking for empty list */
    if (start == NULL)
        return;

    do {
        swapped = 0;
        ptr1 = start;

        while (ptr1->next != lptr) {  
            if (ptr1->number > ptr1->next->number) {  
                swap(ptr1, ptr1->next);
                swapped = 1;
            }
            ptr1 = ptr1->next;
        }
        lptr = ptr1;
    }
    while (swapped);
}

///////////////////////////// CALC PUZZLE OUTPUT (PT1)/////////////////////////

// assume same length
long calc_puzzle_output(struct PuzzleInput *input) {
    struct List *l_next, *r_next;
    long result = 0;

    l_next = input->left;
    r_next = input->right;

    while(l_next != NULL) {
        if(l_next->number >= r_next->number) {
            result += l_next->number - r_next->number;
        } else {
            result += r_next->number - l_next->number;
        }
        
        l_next = l_next->next;
        r_next = r_next->next;
    }

    return result;
}

///////////////////////////// CALC FREQ (PT2) /////////////////////////

long count_occurences(struct List *list, long value) {
    long occurences = 0;
    struct List *next;

    next = list;
    while(next != NULL) {
        if (next->number == value) {
            occurences++;
        }
        next = next->next;
    }

    return occurences;
}

void add_freq(struct PuzzleInput *input) {
    struct List *next;
    
    next = input->left;
    while(next != NULL) {
        next->freq_in_right = count_occurences(input->right, next->number);
        next = next->next;
    }
}

long calc_part_2_output(struct PuzzleInput *input) {
    long sim_score = 0;
    struct List *next;

    add_freq(input);

    next = input->left;
    while(next != NULL) {
        sim_score += next->number * next->freq_in_right;
        next = next->next;
    }

    return sim_score;
}

//////////////////////////////// MAIN /////////////////////////////////////////

int main() {
    struct MemoryStruct *input;
    struct PuzzleInput *parsed_input;

    input = pull_input();

    parsed_input = parse_input(input->memory);

    bubbleSort(parsed_input->left);
    bubbleSort(parsed_input->right);

    print_puzzle_input(parsed_input);

    long result = calc_puzzle_output(parsed_input);
    printf("result (part 1): %ld\n", result);

    long pt_2_result = calc_part_2_output(parsed_input);
    printf("result (part 2): %ld\n", pt_2_result);
    
    free_puzzle_input(parsed_input);
    free(input->memory);
    free(input);
    return 0;
}
