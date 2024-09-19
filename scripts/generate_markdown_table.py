#!/usr/bin/env python3

import argparse
import re
import json
import csv
import sys
import os

def parse_args():
    parser = argparse.ArgumentParser(description='Generate comparative markdown table from Redis benchmark results.')
    parser.add_argument('compiler_csv', nargs='+', help='Compiler name and CSV filename pairs', metavar='COMPILER=CSV_FILE')
    parser.add_argument('--debug', '-d', action='store_true', help='Enable debug output')
    return parser.parse_args()

def clean_command_name(command):
    # Remove content inside parentheses and trim whitespace
    return re.sub(r'\s*\(.*?\)', '', command).strip()

def main():
    args = parse_args()
    debug = args.debug

    compilers = {}
    for pair in args.compiler_csv:
        if debug:
            print(f"Processing pair: '{pair}'")
        compiler_name, filename = pair.split('=', 1)
        if debug:
            print(f"Compiler name: '{compiler_name}'")
            print(f"Filename: '{filename}'")
        compilers[compiler_name] = filename

    commands = {}

    for compiler_name, filename in compilers.items():
        if debug:
            print(f"Reading file '{filename}' for compiler '{compiler_name}'")
        with open(filename, 'r') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                if row['type'] == 'summary':
                    command = clean_command_name(row['command'])
                    total_rps = row['total_rps']
                    p50 = row['p50']
                    if command not in commands:
                        commands[command] = {}
                    commands[command][compiler_name] = {
                        'total_rps': float(total_rps),
                        'p50': float(p50),
                    }
                    if debug:
                        print(f"Read summary for command '{command}': RPS={total_rps}, p50={p50}")

    # Prepare compiler display names (optional)
    compiler_display_names = {name: name.replace('_', ' ') for name in compilers.keys()}

    # Generate the markdown table

    # Header
    headers = ['Command']
    for compiler_name in compilers.keys():
        display_name = compiler_display_names[compiler_name]
        headers.append(f'{display_name} RPS')
        headers.append(f'{display_name} p50')

    # Print the header row
    print('| ' + ' | '.join(headers) + ' |')

    # Separator
    print('|' + '|'.join(['-' * (len(h)+2) for h in headers]) + '|')

    # Define a custom command order (optional)
    preferred_order = [
        'PING_INLINE', 'PING_MBULK', 'SET', 'GET', 'INCR',
        'LPUSH', 'RPUSH', 'LPOP', 'RPOP', 'SADD', 'HSET',
        'SPOP', 'MSET', 'ZADD', 'ZPOPMIN', 'LRANGE_100',
        'LRANGE_300', 'LRANGE_500', 'LRANGE_600', 'XADD',
        # Add any other commands you expect
    ]

    # Use preferred order or sort commands alphabetically
    sorted_commands = preferred_order + sorted(set(commands.keys()) - set(preferred_order))

    # Rows
    for command in sorted_commands:
        if command in commands:
            row = [command]
            for compiler_name in compilers.keys():
                if compiler_name in commands[command]:
                    total_rps = commands[command][compiler_name]['total_rps']
                    p50 = commands[command][compiler_name]['p50']
                    # Format the numbers
                    total_rps_str = f"{total_rps:,.2f}"
                    p50_str = f"{p50:.3f}"
                else:
                    total_rps_str = ''
                    p50_str = ''
                row.append(total_rps_str)
                row.append(p50_str)
            print('| ' + ' | '.join(row) + ' |')

if __name__ == '__main__':
    main()
