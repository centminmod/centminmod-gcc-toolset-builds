#!/usr/bin/env python3

import argparse
import re
import json
import csv
import sys
import os

def parse_args():
    parser = argparse.ArgumentParser(description='Parse Redis benchmark result files.')
    parser.add_argument('-f', '--format', choices=['csv', 'json'], default='csv', help='Output format.')
    parser.add_argument('files', nargs='+', help='Input result files.')
    return parser.parse_args()

def parse_file(filename):
    # Patterns for detailed lines and summary lines
    detail_pattern = re.compile(
        r'^(?P<command>[^:]+):\s+rps=(?P<rps>-?\d+(\.\d+)?)(?: \(overall: [^\)]+\))?\s+avg_msec=(?P<avg_msec>-?\d+(\.\d+)?)(?: \(overall: [^\)]+\))?'
    )
    summary_pattern = re.compile(
        r'^(?P<command>[^:]+):\s+(?P<total_rps>\d+(\.\d+)?) requests per second, p50=(?P<p50>\d+(\.\d+)?) msec'
    )
    data = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            detail_match = detail_pattern.match(line)
            if detail_match:
                entry = {
                    'file': os.path.basename(filename),
                    'command': detail_match.group('command').strip(),
                    'type': 'detail',
                    'rps': float(detail_match.group('rps')),
                    'avg_msec': float(detail_match.group('avg_msec')),
                }
                data.append(entry)
                continue
            summary_match = summary_pattern.match(line)
            if summary_match:
                entry = {
                    'file': os.path.basename(filename),
                    'command': summary_match.group('command').strip(),
                    'type': 'summary',
                    'total_rps': float(summary_match.group('total_rps')),
                    'p50': float(summary_match.group('p50')),
                }
                data.append(entry)
    return data

def main():
    args = parse_args()
    all_data = []
    for filename in args.files:
        file_data = parse_file(filename)
        all_data.extend(file_data)

    if args.format == 'csv':
        fieldnames = ['file', 'command', 'type', 'rps', 'avg_msec', 'total_rps', 'p50']
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        for row in all_data:
            writer.writerow(row)
    else:  # JSON format
        json.dump(all_data, sys.stdout, indent=2)

if __name__ == '__main__':
    main()
