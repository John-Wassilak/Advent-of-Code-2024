import requests
import os
from http.cookies import SimpleCookie

# python ./12-02.py
# 
# the real challenge is how much whiskey can be had and still succeed
# edit : a lot

#################### PARSE INPUT ##############################################

# requires AOC_COOKIE env variable to be set
def get_raw_input():
    cookie = SimpleCookie()
    cookie.load(os.environ['AOC_COOKIE'])
    session = requests.Session()
    for key, morsel in cookie.items():
        session.cookies.set(morsel.key, morsel.value,
                            domain=morsel['domain'], path=morsel['path'])

    response = session.get('https://adventofcode.com/2024/day/2/input')

    return response.text

def parse_raw_input(input):
    parsed = []

    for line in input.splitlines():
        print(line)
        row = []
        for item in line.split(" "):
            row.append(int(item))
        parsed.append(row)

    return parsed

################################# TEST INPUT P1  ################################

def is_all_dec_and_in_range(list):
    result = True
    i = 1
    while i < len(list):
        if(list[i] >= list[i-1]):
            result = False
        elif((list[i-1] - list[i]) > 3):
            result = False
        i += 1
    return result

def is_all_inc_and_in_range(list):
    result = True
    i = 1
    while i < len(list):
        if(list[i] <= list[i-1]):
            result = False
        elif((list[i] - list[i-1]) > 3):
            result = False
        i += 1
    return result

def is_safe(row):
    return (is_all_inc_and_in_range(row) or is_all_dec_and_in_range(row))

def count_safe_reports(list):
    safe = 0;
    
    for row in list:
        if is_safe(row):
            safe += 1

    return safe

################################# TEST INPUT P2  ################################

# i'm not proud, popping one out and testing again, and again, and again
def count_safe_reports_p2(list):
    safe = 0;

    for row in list:
        if is_safe(row):
            safe += 1
        else:
            i = 0
            while i < len(row):
                row_cpy = row.copy()
                row_cpy.pop(i)
                if is_safe(row_cpy):
                    safe += 1
                    break
                else:
                    i += 1
    return safe

raw_input = get_raw_input()
parsed = parse_raw_input(raw_input)

print(f"p1: {count_safe_reports(parsed)}")

print(f"p2: {count_safe_reports_p2(parsed)}")
