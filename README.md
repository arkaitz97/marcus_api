# Marcus API

## Description

This is a Ruby on Rails API designed to manage configurable products. It allows users to define products, their constituent parts, various options for those parts, and rules governing the relationships between options (like incompatibilities and price adjustments).

The API provides endpoints for CRUD (Create, Read, Update, Delete) operations on the following resources:  
* Products  
* Parts (belonging to Products)  
* Part Options (belonging to Parts)  
* Part Restrictions (defining incompatibilities between Part Options)  
* Price Rules (defining price premiums for combinations of Part Options)

## Prerequisites

Before you begin, ensure you have the following installed:

* **Ruby:** (e.g., 3.1.x, 3.2.x or newer). Using a version manager like `rbenv` or `rvm` is recommended.  
* **Bundler:** (`gem install bundler`)  
* **Rails:** (e.g., 7.x or the version specified in the Gemfile - `gem install rails`)  
* **SQLite3:** The development libraries might be needed (`libsqlite3-dev` on Debian/Ubuntu, `sqlite-devel` on Fedora/CentOS, `sqlite` via Homebrew on macOS).

## Setup Instructions

1.  **Clone the Repository:**  
    ```bash  
    git clone https://github.com/arkaitz97/marcus_api
    cd marcus_api
    ```  

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
    # bin/rails db:create    
    # bin/rails db:migrate  
    ```

## Running the Server

To start the Rails development server (Puma):

```bash  
bin/rails server
```
Or using the shorthand:
```
bin/rails s
```

The API will typically be available at http://localhost:3000.

## **Running Tests**

A basic test script (test_api.sh) is provided to exercise the API endpoints.

**Requirements:**

* The Rails server must be running.  
* curl command-line tool.  
* jq command-line JSON processor.

**Execution:**

1. Make the script executable: chmod +x test_api.sh  
2. Run the script: ./test_api.sh

The script performs CRUD operations on all resources and reports basic pass/fail status.

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
  * PUT/PATCH /products/:product_id/parts/:part_id/part_options/:id: Update an existing part option  
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

## **Data Model & Design Decisions**

Several choices were made during the development of this API:

* **API-Only Mode (--api):** The Rails application was generated using the --api flag. This creates a lighter-weight application by excluding middleware and modules typically used for browser-based interactions (like sessions, cookies, flash messages, asset pipeline, views). This is ideal for a backend service consumed by other applications (e.g., a frontend framework, mobile app).  
* **SQLite Database:** SQLite was chosen for its simplicity. It's a file-based database requiring no separate server process, making it very easy to set up for development and prototyping. For production environments with higher concurrency or scalability needs, migrating to a database like PostgreSQL or MySQL would be recommended.  
* **Nested Routes (Parts, PartOptions):** The routes for Parts are nested under Products, and PartOptions are nested under Parts. This reflects the belongs_to relationships in the data model directly within the URL structure (e.g., /products/1/parts/5). It provides clear context and follows RESTful principles for hierarchical data.  
* **Top-Level Routes (Restrictions, PriceRules):** PartRestrictions and PriceRules represent relationships *between* PartOption records, rather than being direct children of a single parent. Nesting them under /products/:product_id/parts/:part_id/part_options/:part_option_id/... would become very cumbersome and doesn't accurately reflect their nature as separate rule sets. Therefore, they are implemented as top-level resources (/part_restrictions, /price_rules).  
* **Database Integrity (references, Foreign Keys, Indices):** Using t.references in migrations automatically creates foreign key constraints (e.g., ensuring a Part's product_id actually exists in the products table) and database indices on these foreign key columns, which improves data integrity and query performance.  
* Data Cleanup (dependent: :destroy): The has_many associations (e.g., Product has_many :parts) include dependent: :destroy. This ensures that when a parent record is deleted, its associated child records are automatically deleted as well (e.g., deleting a Product also deletes all its Parts and, transitively, their PartOptions). This helps maintain data consistency.:  
* **Business Logic Validation (Restrictions/PriceRules):** Beyond database constraints, model-level validations were added to PartRestriction and PriceRule to enforce specific business logic:  
  * Preventing self-references (e.g., an option cannot restrict itself).  
  * Ensuring symmetry (e.g., if "A restricts B" exists, preventing the creation of "B restricts A").  
* **Price Data Type (decimal):** The price attribute on PartOption and price_premium on PriceRule use the decimal data type with specified precision and scale. This is crucial for financial calculations to avoid the potential inaccuracies associated with floating-point numbers (float).  
* **Security (Strong Parameters):** All controllers use strong parameters (params.require(...).permit(...)). This is a vital security measure in Rails to prevent mass assignment vulnerabilities, ensuring that only explicitly allowed attributes can be updated through API requests.