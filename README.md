
# SQL Data Warehouse Project

This repository demonstrates the design and implementation of a
modern SQL data warehouse using a layered architecture.

## Architecture
The project follows a Bronze, Silver, and Gold layer approach:

- Bronze: Raw source data ingested from CSV files
- Silver: Cleaned and standardized datasets
- Gold: Analytics-ready views modeled using a star schema

## Repository Structure

datasets/
- Raw source CSV files (Bronze layer)

scripts/
- SQL scripts for Bronze, Silver, and Gold transformations

data_catalog/
- Documentation for Gold layer tables and views

## Gold Layer Objects
- dim_customers
- fact_sales

## Purpose
This project was built to practice real-world data warehousing concepts
including data modeling, transformations, and documentation.
