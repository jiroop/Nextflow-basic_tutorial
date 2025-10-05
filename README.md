# Nextflow Tutorial Pipeline

A simple Nextflow pipeline for learning the basics of workflow management. 
This follows the workflow specified here: https://nextflow.io/docs/latest/your-first-script.html

## Description

This pipeline demonstrates core Nextflow concepts:
- Process definitions
- Channel operations
- Input/output handling

## What It Does

1. **Split Process**: Splits an input string into 6-byte chunks
2. **Convert to Upper Process**: Converts each chunk to uppercase

## Requirements

- Nextflow 24.04+
- Java 17+

## Usage

Run with default parameters:
```bash
nextflow run main.nf