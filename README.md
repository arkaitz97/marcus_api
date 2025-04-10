# Product Configurator API

## Description

This is a Ruby on Rails API designed to manage configurable products. It allows users to define products, their constituent parts, various options for those parts, and rules governing the relationships between options (like incompatibilities and price adjustments). It also allows placing orders for specific product configurations.

The API provides endpoints for CRUD (Create, Read, Update, Delete) operations on the following resources:  
* Products  
* Parts (belonging to Products)  
* Part Options (belonging to Parts)  
* Part Restrictions (defining incompatibilities between Part Options)  
* Price Rules (defining price premiums for combinations of Part Options)  
* Orders (representing customer selections)

## Prerequisites

Before you begin, ensure you have the following installed:

* **Ruby:** (e.g., 3.1.x, 3.2.x or newer). Using a version manager like `rbenv` or `rvm` is recommended.  
* **Bundler:** (`gem install bundler`)  
* **Rails:** (e.g., 7.x or the version specified in the Gemfile - `gem install rails`)  
* **SQLite3:** The development libraries might be needed (`libsqlite3-dev` on Debian/Ubuntu, `sqlite-devel` on Fedora/CentOS, `sqlite` via Homebrew on macOS).

## Setup Instructions

1.  **Clone the Repository:**  
    ```bash  
    git clone \<your-repository-url\>  
    cd product_configurator_api  
    ```  
    *(Replace `\<your-repository-url\>` with the actual URL)*

2.  **Install Dependencies:**  
    Install the required gems as specified in the `Gemfile`:  
    ```bash  
    bundle install  
    ```

3.  **Setup Database:**  
    Create the database, load the schema, and run any seed data (if defined):  
    ```bash  
    bin/rails db:setup  
    ```  
    *Alternatively, if you prefer manual steps:*  
    ```bash  
    bin/rails db:create  # Creates development and test databases  
    bin/rails db:migrate # Runs migrations to set up tables  
    bin/rails db:seed    # Runs the seed file  
    ```

## Running the Server

To start the Rails development server (Puma) **on port 3001**:

```bash  
bin/rails server -p 3001
```

Or using the shorthand:  
```bash
bin/rails s -p 3001
```

The API will typically be available at http://localhost:3001.

## **Running Tests**

A basic test script (test_api.sh) is provided to exercise the API endpoints.  
**Requirements:**

* The Rails server must be running **on port 3001**.  
* curl command-line tool.  
* jq command-line JSON processor.

**Execution:**

1. Make the script executable: chmod +x test_api.sh  
2. Run the script: ./test_api.sh

The script performs CRUD operations on all resources and reports basic pass/fail status. *Note: Ensure the script is updated for all implemented endpoints, including Orders and Dynamic Configuration.*

## **API Endpoints**

All endpoints are prefixed with /api/v1.

* **Products**  
  * GET /products: List all products  
  * GET /products/:id: Get details of a specific product  
  * POST /products: Create a new product  
  * PUT/PATCH /products/:id: Update an existing product  
  * DELETE /products/:id: Delete a product  
* **Parts** (Nested under Products)  
  * GET /products/:product_id/parts: List parts for a specific product  
  * GET /products/:product_id/parts/:id: Get details of a specific part  
  * POST /products/:product_id/parts: Create a new part for a product  
  * PUT/PATCH /products/:product_id/parts/:id: Update an existing part  
  * DELETE /products/:product_id/parts/:id: Delete a part  
* **Part Options** (Nested under Parts)  
  * GET /products/:product_id/parts/:part_id/part_options: List options for a specific part  
  * GET /products/:product_id/parts/:part_id/part_options/:id: Get details of a specific part option  
  * POST /products/:product_id/parts/:part_id/part_options: Create a new option for a part  
  * PUT/PATCH /products/:product_id/parts/:part_id/part_options/:id: Update an existing part option (incl. in_stock)  
  * DELETE /products/:product_id/parts/:part_id/part_options/:id: Delete a part option  
* **Part Restrictions** (Top Level)  
  * GET /part_restrictions: List all part restriction rules  
  * GET /part_restrictions/:id: Get details of a specific restriction rule  
  * POST /part_restrictions: Create a new restriction rule (link two options)  
  * DELETE /part_restrictions/:id: Delete a restriction rule  
* **Price Rules** (Top Level)  
  * GET /price_rules: List all price rules  
  * GET /price_rules/:id: Get details of a specific price rule  
  * POST /price_rules: Create a new price rule (link two options)  
  * DELETE /price_rules/:id: Delete a price rule  
* **Orders** (Top Level)  
  * GET /orders: List all orders  
  * GET /orders/:id: Get details of a specific order (incl. selected options)  
  * POST /orders: Create a new order (requires customer info and selected_part_option_ids)  
  * PUT/PATCH /orders/:id: Update an existing order (e.g., change status)  
  * DELETE /orders/:id: Delete/cancel an order  
* **Dynamic Configuration Endpoints** (Top Level)  
  * POST /product_configuration/validate_selection: Validate options ({ selected_part_option_ids: [...] }). Returns { valid: boolean, errors: [...] }.  
  * POST /product_configuration/calculate_price: Calculate price ({ selected_part_option_ids: [...] }). Returns { total_price: "string" }.

## **Data Model & Design Decisions**

Several choices were made during the development of this API:

* **API-Only Mode (--api):** Creates a lighter-weight application suitable for a backend service.  
* **SQLite Database:** Chosen for simplicity in development; recommend PostgreSQL or MySQL for production.  
* **Nested Routes (Parts, PartOptions):** Reflects belongs_to relationships and provides context.  
* **Top-Level Routes (Restrictions, PriceRules, Orders, Config):** Used for resources that don't naturally fit the nested hierarchy or represent cross-cutting concerns.  
* **Database Integrity (references, Foreign Keys, Indices):** t.references ensures referential integrity and improves lookup performance.  
* **Data Cleanup (dependent: :destroy):** Ensures associated records are removed when a parent is deleted, maintaining consistency.  
* **Business Logic Validation:** Model and controller validations enforce rules beyond basic database constraints (e.g., rule symmetry, stock checks, restriction checks during order creation).  
* **Price Data Type (decimal):** Used for currency values to avoid floating-point inaccuracies.  
* **Security (Strong Parameters):** Protects against mass assignment vulnerabilities.  
* **Order Creation Logic:** Centralized in OrdersController (consider Service Objects for more complex apps). Includes validation and price calculation.ic

* ## **Stock Management: Implemented via an in_stock boolean on PartOption, managed through the standard PartOption endpoints.**   